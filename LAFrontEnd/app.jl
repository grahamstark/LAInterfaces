module App

using GenieFramework
include( "lib/LAUtils.jl")

using .LAUtils

using PlotlyBase
using Format
using DataFrames
import GenieFramework.Stipple.opts

@genietools

fm( x ) = Format.format( x, commas=true )

# settings = LAUtils.initialise(reset=true) # LAUtils.make_default_settings()


laout = LAUtils.run( LAUtils.SETTINGS, nothing )


function get_table( laout, name::Symbol, sysno = 1)
    t = laout.civil.breakdown_pers[sysno][name]
    t[:,2:end] .= round.( t[:,2:end] )
    # return DataFrame(hcat(t[1,:],Format.format.(t[:,2:end],precision=0, commas=true)),:auto)
end

@app begin

    @in other_dependants_allowance = 0.0
    
    # @out decbar = getbase( :decbar )
    @out other_dependants_allowancepw = fm(LAUtils.BASE_SYS.legalaid.civil.income_other_dependants_allowance)
    @out crosstab = LAUtils.format_crosstab( zeros(4,4))
    @out emptable = DataTable(get_table( laout, :employment_status, 1 ))
    # FIXME all this tables malarkey isn't needed. See:
    # https://genieframework.com/docs/stippleui/v0.20/API/tables.html
    #=
    @out deciles = DataTable(getbase(:deciles)[:,[:decile,:average_change_pw]])
    =#
    @onchange other_dependants_allowance begin 
        println( "#2")
        # out = make_base_run( other_dependants_allowance )        
        other_dependants_allowancepw = fm( other_dependants_allowance )
        laout = LAUtils.run( LAUtils.SETTINGS, other_dependants_allowance )
        emptable =  DataTable(get_table( laout, :employment_status, 2 ))
        emptable.opts.columnspecs[r".*"] = opts(format = jsfunction(raw"(val, row) => `${100*val.toFixed(3)}%`"))
        println( "emptable=$emptable")
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
                span("Other Dependants Allowance (£p.a):" )
                slider(0.0:10:20_000,:other_dependants_allowance)
                p("other_dependants_allowance: <b>£{{other_dependants_allowancepw}}</b> p.a.")
                
            ]),
            cell([
                GenieFramework.table( :emptable )
            ])
        ])
        #=
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
        =#
        ,Genie.Renderer.Html.render(LAUtils.format_crosstab( zeros(4,4)))
    ]
end


println( "before page")
@page( "/", ui )
println( "after page")

end # module