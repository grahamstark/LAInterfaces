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
using .Definitions
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
  settings.export_full_results = true
  settings.do_legal_aid = true
  settings.requested_threads = 6
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
  @argcheck size( crosstab ) == (4,4)
  labels = ["Not Entitled","W/Contribution","Fully Entitled","Passported"]

  t = """
  <table class='table table-sm'>
        <thead>
        <caption>$caption</caption>
        </thead>
        <tbody>
    """
    tr = "<tr><th></th>"
    for c in 1:4
        cell = "<th>$(labels[c])</th>"
    end
    tr *= "</tr>"
    t *= tr
    for r in 1:4
        tr = """
            <tr><th>$(labels[r])</th>
        """
        for c in 1:4
            v = fmt( crosstab[r,c] )
            colour = if r == c # on the diagonal
                "text-secondary"
            elseif r < c # above the diagonal
                "text-success"
            else # below the diagonal
                "text-danger"
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
    # println(tot)
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  # overwrite with annualised version
  sys.legalaid.civil = STBParameters.default_civil_sys( 2023, Float64 )
  sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

function do_run( la2 :: OneLegalAidSys; iscivil=true )
  global tot
  tot = 0
  sys2 = deepcopy(DEFAULT_SYS)
  if iscivil
    sys2.legalaid.civil = la2
    weeklyise!( sys2.legalaid.civil )
  else
    sys2.legalaid.aa = la2
  end  
  allout = LegalAidRunner.do_one_run( DEFAULT_SETTINGS, [DEFAULT_SYS,sys2], obs )
  return allout
end

const DEFAULT_PARAMS =  make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()
const DEFAULT_RUN = do_run( DEFAULT_PARAMS.legalaid.civil )
const DEFAULT_OUTPUT = results_to_html( DEFAULT_RUN )

const up = Genie.up
export up

function sysfrompayload( payload ) :: OneLegalAidSys
  @show payload
  pars = JSON3.read( payload )
  # make this swappable to aa
  sys = deepcopy( deepcopy(DEFAULT_SYS.legalaid.civil ))
  sys.income_living_allowance           = parse(Float64, pars.income_living_allowance )
  sys.income_partners_allowance         = parse(Float64, pars.income_partners_allowance )
  sys.income_other_dependants_allowance = parse(Float64, pars.income_other_dependants_allowance )
  sys.income_child_allowance            = parse(Float64, pars.income_child_allowance )
  
  # capital_allowances                = RT.([])    
  # income_cont_type = cont_proportion 

  return sys
end

function results_to_html( 
  results      :: NamedTuple ) :: NamedTuple
  # table expects a tuple
  crosstab = format_crosstab( results.civil.crosstab_pers[1] )
  (; crosstab )
end

function reset()
  (; output=DEFAULT_OUTPUT, 
     params = DEFAULT_PARAMS.legal.civil,
     defaults = DEFAULT_PARAMS.legal.civil ) |> json
end

function run()
  lasys = sysfrompayload( rawpayload())
  lares = do_run( lasys )
  output = results_to_html( lares )
  params = lasys
  defaults = DEFAULT_PARAMS.legalaid.civil
  (; output, params, defaults ) |> json
end

function main()
  Genie.genie(; context = @__MODULE__)
end

end
