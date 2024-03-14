#


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
    return t 
end




# TOLIBRARY
function results_to_html( 
    results      :: AllLegalOutput ) :: NamedTuple
    # table expects a tuple
    k = "$(LegalAidData.PROBLEM_TYPES[1])-$(LegalAidData.ESTIMATE_TYPES[2])"
    crosstab = format_crosstab( results.civil.crosstab_pers[1][k] )
    (; crosstab )
end
  
