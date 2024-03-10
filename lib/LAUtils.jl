module LAUtils

using CSV 
using DataFrames
using Format
using StatsBase 
using Observables
using ArgCheck

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .Monitor: Progress
using .RunSettings
using .Definitions
using .STBParameters: TaxBenefitSystem, get_default_system_for_fin_year
using .Utils

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .LegalAidRunner


export run, make_default_settings


export WEEKS_PER_YEAR

export make_default_settings, format_crosstab


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

const SETTINGS = make_default_settings()

function make_default_sys()
    sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
    sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
    return sys
end 

const BASE_SYS = make_default_sys()

function fmt(v::Number)::String 
    Format.format( v, precision=0, commas=true )
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

function frame_to_table(
    df :: DataFrame;
    up_is_good :: Vector{Int},
    prec :: Int = 2, 
    caption :: String = "",
    totals_col :: Int = -1 )
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'>Baseline Policy</th><th style='text-align:right'>Your Policy</th><th style='text-align:right'>Change</th>            
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        fmtd = format_diff( before=r.Before, after=r.After, up_is_good=up_is_good[i], prec=prec )
        row_style = i == totals_col ? "class='text-bold table-info' " : ""
        row = "<tr $row_style><th class='text-left'>$(r.Item)</th>
                  <td style='text-align:right'>$(fmtd.before_s)</td>
                  <td style='text-align:right'>$(fmtd.after_s)</td>
                  <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

export run, initialise

tot = 0
obs = Observable( Monitor.Progress( SETTINGS.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
    # println(tot)
end

function run( settings :: Settings, other_dependents_allowance = nothing ) #::Union{Nothing,Real} )
    global tot
    println( "running $other_dependents_allowance")
    tot = 0
    sys2 = deepcopy(BASE_SYS)
    
    if ! isnothing( other_dependents_allowance )
        sys2.legalaid.civil.income_other_dependants_allowance = 
            other_dependents_allowance/WEEKS_PER_YEAR
    end
    laout = LegalAidRunner.do_one_run( settings, [BASE_SYS,sys2], obs )
    return laout
end
  

end
