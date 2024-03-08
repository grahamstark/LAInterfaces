module App

using GenieFramework
using Main.LAUtils
using PlotlyBase
using Format
using DataFrames

@genietools

settings = LAUtils.initialise(reset=true) # LAUtils.make_default_settings()

function make_base_run(other_dependants_allowance)
    out = LAUtils.run( settings, other_dependants_allowance )
    println( "settings=$(settings)")
    println( out[1:10,:])
    deciles = LAUtils.tabulate( out, :decile )
    deciles.average_change_pw = Formatting.format.(deciles.average_change, precision=2)
    println( names(deciles))
    tenures = LAUtils.tabulate( out, :tenure )
    tenures.average_change_pw = Formatting.format.(tenures.average_change, precision=2)

    regions = LAUtils.tabulate( out, :region )
    regions.average_change_pw = Formatting.format.(regions.average_change, precision=2)
    children = LAUtils.tabulate( out, :children )
    children.average_change_pw = Formatting.format.(children.average_change, precision=2)
    decbar = [
        bar( 
            x=deciles.decile, 
            y=deciles.average_change )]
    base_revenues = WEEKS_PER_YEAR*sum( out.weighted_water_1 )
    println("make base run exiting")
    (; deciles, tenures, regions, base_revenues, children, decbar )
end

const BASE_RUN = make_base_run(1.0)

function getbase(which::Symbol)
    BASE_RUN[which]
end

@app begin

    @in other_dependants_allowance = 0.0
    
    @out decbar = getbase( :decbar )
    # FIXME all this tables malarkey isn't needed. See:
    # https://genieframework.com/docs/stippleui/v0.20/API/tables.html
    @out deciles = DataTable(getbase(:deciles)[:,[:decile,:average_change_pw]])
    @out tenures = DataTable(getbase(:tenures))[:,[:tenure,:average_change_pw]]
    @out regions = DataTable(getbase(:regions))[:,[:region,:average_change_pw]]
    @out children = DataTable(getbase(:children))[:,[:children,:average_change_pw]]
    @out data_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)
    @out billchange = 0.0
    @out other_dependants_allowancemn = "0"
    @out plotlayout = PlotlyBase.Layout(
        title="Change in Water and Sewerage Bills From Poorest To Richest",
        yaxis=attr(
            title="Extra Water Bill in £s pw",
            showgrid=true,
            range=[0, 20]
        ),
        xaxis=attr(
            title="Household Income Decile",
            showgrid=true
        ),

    )

    println( "#1")
    br = getbase(:base_revenues)
    println( "base_revenues $br") 
    @onchange other_dependants_allowance begin 
        println( "#2")
        println( "#3")
        out = make_base_run( 1+(billchange/100.0) )
        
        other_dependants_allowancepw = Formatting.format( other_dependants_allowance/1_000_000, commas=true )
    end 
    println("after on change")
end

function ui()
    [
        row([
            cell([
                h1("LEGAL AID")
            ]),
        ]),
        row([
            cell([
                span("income: Other Dependants Allowance (£sp.a):" )
                slider(0.0:10:20_000,:other_dependants_allowance)
                p("other_dependants_allowance: <b>£{{other_dependants_allowancepw}}</b> p.a.")
            ]),
            cell([
                """ 
                <h2>LEGAL AID SIM</h2>

        """
            ])
        ]),
        row([
            cell([
                plot(:decbar; layout=:plotlayout )
            ])
        ]),

        row([
            cell([
                GenieFramework.table(:deciles; title="By Decile", pagination=:data_pagination)
            ])
        ])
    ]
end


println( "before page")
@page( "/", ui )
println( "after page")

end # module