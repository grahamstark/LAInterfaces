#


function fmt(v::Number)::String 
    Format.format( v, precision=0, commas=true )
  end
  
function fmt2(v::Number)::String 
    Format.format( v, precision=2, commas=true )
end

function format_crosstab( 
    crosstab :: Matrix; 
    title="", 
    caption = "", 
    add_wrapper = false ) :: AbstractString
    
    @argcheck size( crosstab ) == (5,5)
    labels = ["Passported","Fully Entitled", "W/Contribution","Not Entitled", "Total"]

    t = """
    <table class='table'>
            <thead>
            <caption>$caption</caption>
            </thead>
            <tbody>
        """
        tr = "<tr><td></td><td colspan='5' style='text-align:center' class='justify-content-center'>Old System</td><tr><td rowspan='8' class='align-middle'>New System</td><tr><th></th>"
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
    
    if add_wrapper
    t ="""
            <div class='row'>
                <div class='col'>
                    <h5>$title</h5>
                    $t
                </div>
            </div>
    """
    end
    return t 
end

# TOLIBRARY
function results_to_html( 
    results      :: AllLegalOutput ) :: NamedTuple
    # table expects a tuple
    k = "$(LegalAidData.PROBLEM_TYPES[1])-$(LegalAidData.ESTIMATE_TYPES[2])"
    crosstab = format_crosstab( results.civil.crosstab_pers[1][k]; 
        caption="Changes to elgibility: all Scottish Adults." )
    crosstabtables = "<div>"
    ctno = 1
    pc = format_crosstab( results.civil.crosstab_bu[ctno]; 
        caption="Benefit Units", 
        add_wrapper=true, 
        title="Entilemment - Benefit Units"  )
    crosstabtables *= pc
    crosstabtables *= "<div class='row'><div class='col'><h3>Tables By Problem Type</h3></div></div>"
    for p in LegalAidData.PROBLEM_TYPES[2:end]
        prettyprob = Utils.pretty(p)
        crosstabtables *= "<div class='row'><div class='col'><h4>Personal Level Tables For Problem Type: $prettyprob</h4></div></div>"
        for est in LegalAidData.ESTIMATE_TYPES
            prettyest = Utils.pretty(est)
            title = "Estimate $(prettyest)"
            k = "$(p)-$(est)"
            pc =  format_crosstab( 
                results.civil.crosstab_pers[ctno][k];
                title = title,
                caption = "Estimated number of Scottish adults experiencing $prettyprob in a 3-year period, by eligibility type; estimate: $prettyest",
                add_wrapper = true ) 
            crosstabtables *= pc
        end
    end
    crosstabtables *= "</div>"
    (; crosstab, crosstabtables )
end
  
