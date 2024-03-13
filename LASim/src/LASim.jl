# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)


module LASim

using Genie
using Genie.Requests
import JSON3
import Genie.Renderer.Json: json
using CSV 
using DataFrames
using Format
using StatsBase 
using Observables
using ArgCheck
using UUIDs

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .Monitor: Progress
using .RunSettings
using .Results
using .Definitions
using .STBIncomes
using .STBParameters: 
  TaxBenefitSystem, 
  get_default_system_for_fin_year, 
  OneLegalAidSys, 
  ScottishLegalAidSys, 
  weeklyise!

using .Utils

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .LegalAidRunner

function make_default_settings() :: Settings
  settings = Settings()
  settings.export_full_results = true
  settings.do_legal_aid = true
  settings.do_marginal_rates = false
  settings.requested_threads = 4
  settings.num_households, settings.num_people, nhh2 = 
      FRSHouseholdGetter.initialise( settings; reset=true ) # force Scottish dataset 
  # ExampleHouseholdGetter.initialise( settings ) # force a reload for reasons I don't quite understand.
  return settings
end

function fmt(v::Number)::String 
  Format.format( v, precision=0, commas=true )
end

function fmt2(v::Number)::String 
  Format.format( v, precision=2, commas=true )
end

function format_crosstab( crosstab :: Matrix, caption = "") :: AbstractString
  @argcheck size( crosstab ) == (5,5)
  labels = ["Passported","Fully Entitled", "W/Contribution","Not Entitled", "Total"]

  t = """
  <table class='table'>
        <thead>
        <caption>$caption</caption>
        </thead>
        <tbody>
    """
    tr = "<tr><td></td><td colspan='5' style='text-align:center' class='justify-content-center'>Old System</td><tr><td rowspan='7' class='align-middle'>New System</td><tr><th></th>"
    for c in 1:5
        cell = "<th>$(labels[c])</th>"
        tr *= cell
    end
    tr *= "</tr>"
    t *= tr
    for r in 1:5
        tr = """
            <tr><th>$(labels[r])</th>
        """
        for c in 1:5
            v = fmt( crosstab[r,c] )
            colour = if( r == 5) && ( c == 5)
                "table-primary"
            elseif(r == 5) || (c == 5) # totals
                "table-info"
            elseif r == c # on the diagonal
                "table-primary"
            elseif r < c # above the diagonal
                "table-success"
            else # below the diagonal
                "table-danger"
            end
            cell = "<td class='text-right $colour' style='text-align:right'>$v</td>"
            tr *= cell
        end
        tr *= "</tr>"
        t *= tr
    end
    t *= """   
    </tbody>     
  </table>
  """
  return t 
end

tot = 0

obs = Observable( Monitor.Progress( UUIDs.uuid4(),"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
end

# included_capital = WealthSet([net_financial_wealth,net_physical_wealth])


mutable struct LASubsys{T}
  income_living_allowance :: T       
  income_partners_allowance   :: T        
  income_other_dependants_allowance :: T  
  income_child_allowance   :: T   
  INCOME_SUPPORT_passported :: Bool
  NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported :: Bool
  NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported  :: Bool
  UNIVERSAL_CREDIT_passported  :: Bool      
end

function LASubsys( sys :: OneLegalAidSys )
  LASubsys(
    sys.income_living_allowance,
    sys.income_partners_allowance,        
    sys.income_other_dependants_allowance,
    sys.income_child_allowance,
    INCOME_SUPPORT in sys.passported_benefits,
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE in sys.passported_benefits,
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE in sys.passported_benefits, 
    UNIVERSAL_CREDIT in sys.passported_benefits)
end

"""
annualised
"""
function default_la_sys()::LASubsys
  civil = STBParameters.default_civil_sys( 2023, Float64 )
  return LASubsys(civil)
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()

function do_run( la2 :: OneLegalAidSys; iscivil=true )
  global tot
  tot = 0
  sys2 = deepcopy(DEFAULT_PARAMS)
  if iscivil
    sys2.legalaid.civil = deepcopy(la2)
    # weeklyise!( sys2.legalaid.civil )
  else
    sys2.legalaid.aa = la2
  end  
  allout = LegalAidRunner.do_one_run( DEFAULT_SETTINGS, [DEFAULT_PARAMS,sys2], obs )
  return allout
end


# TOLIBRARY
function results_to_html( 
  results      :: AllLegalOutput ) :: NamedTuple
  # table expects a tuple
  k = "$(LegalAidData.PROBLEM_TYPES[1])-$(LegalAidData.ESTIMATE_TYPES[2])"
  crosstab = format_crosstab( results.civil.crosstab_pers[1][k] )
  (; crosstab )
end


const DEFAULT_RUN = do_run( DEFAULT_PARAMS.legalaid.civil )
const DEFAULT_OUTPUT = results_to_html( DEFAULT_RUN )

const up = Genie.up
export up




function sysfrompayload( payload ) :: Tuple
  pars = JSON3.read( payload, LASubsys{Float64})
  @show pars
  
  # make this swappable to aa
  sys = deepcopy( DEFAULT_PARAMS.legalaid.civil )
  sys.income_living_allowance           = pars.income_living_allowance/WEEKS_PER_YEAR
  sys.income_partners_allowance         = pars.income_partners_allowance/WEEKS_PER_YEAR
  sys.income_other_dependants_allowance = pars.income_other_dependants_allowance/WEEKS_PER_YEAR
  sys.income_child_allowance            = pars.income_child_allowance/WEEKS_PER_YEAR
  if pars.INCOME_SUPPORT_passported 
    push!( sys.passported_benefits, INCOME_SUPPORT )
  else
    try
      pop!(sys.passported_benefits,INCOME_SUPPORT)
    catch
    end
  end
  if pars.NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported 
    push!( sys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
  else
    try
      pop!(sys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE)
    catch
    end
  end
  if pars.NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported
    push!( sys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
  else
    try
      pop!(sys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    catch
    end
  end
  if pars.UNIVERSAL_CREDIT_passported
    push!( sys.passported_benefits, UNIVERSAL_CREDIT )
  else
    try
      pop!(sys.passported_benefits, UNIVERSAL_CREDIT )
    catch
    end
  end
  return sys, pars
end

function reset()
  defaults = default_la_sys()
  @info defaults
  (; output=DEFAULT_OUTPUT, 
     params = defaults,
     defaults = defaults ) |> json
end

function run()
  lasys, params = sysfrompayload( rawpayload()) 
  lares = do_run( lasys )
  output = results_to_html( lares )
  # params = lasys
  defaults = default_la_sys() #DEFAULT_PARAMS.legalaid.civil
  (; output, params, defaults ) |> json
end

function main()
  Genie.genie(; context = @__MODULE__)
end

end
