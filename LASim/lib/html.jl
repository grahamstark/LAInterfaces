#


function fmt(v::Number)::String 
    Format.format( v, precision=0, commas=true )
  end
  
function fmt2(v::Number)::String 
    Format.format( v, precision=2, commas=true )
end


function format_diff(; before :: Number, after :: Number, up_is_good = 1, prec=0,commas=true ) :: NamedTuple
    change = round(after - before, digits=6)
    colour = ""
    if (up_is_good !== 0) && (! (change ≈ 0))
        if change > 0
            colour = up_is_good == 1 ? "text-success" : "text-danger"
        else
            colour = up_is_good == 1 ? "text-danger" : "text-success"
        end # neg diff   
    end # non zero diff
    ds = change ≈ 0 ? "-" : format(change, commas=true, precision=prec )
    if ds != "-" && change > 0
        ds = "+$(ds)"
    end 
    before_s = format(before, commas=commas, precision=prec)
    after_s = format(after, commas=commas, precision=prec)    
    (; colour, ds, before_s, after_s )
end


function format_crosstab( 
    crosstab :: Matrix; 
    title="", 
    caption = "" ) :: AbstractString
    
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

function wraptable( title, table )
    return """
    <div class='row'>
        <div class='col'>
            <h5>$title</h5>
            $table
        </div>
    </div>
"""
end

function add_col_totals!( df::DataFrame, add_label = false )
    nrows, ncols = size( df )
    newrow = deepcopy( df[1,:])
    for c in 1:ncols
        col = df[:,c]
        println( "eltype col[$col] $(eltype( col ))")
        if eltype( col ) <: Number 
            newrow[c] = sum( col )
        end
        if add_label
            newrow[1] = "Totals"
        end
    end
    push!( df, newrow )
end

function frame_to_table(
    ;
    pre_df  :: DataFrame,
    post_df :: DataFrame,
    caption :: String = "" )
    @argcheck size( pre_df ) == size( post_df )
    colnames = Utils.pretty.( names( pre_df ))
    headers = "<th></th><th colspan='2'>" * join( colnames[2:end], "</th><th colspan='2'>" ) * "</th>"
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <caption>$(caption)</caption>
        <tr>
        $(headers)
        </tr>
        </thead>"
    add_col_totals!( pre_df )
    add_col_totals!( post_df )
    
    nrows, ncols = size( pre_df )

    for r in 1:nrows
        prer = pre_df[r,:]
        postr = post_df[r,:]
        row_style = r == nrows ? "class='text-bold table-info' " : ""
        rowlabel = r == nrows ? "Totals" : Utils.pretty(prer[1])
        row = "<tr $row_style><th>$rowlabel</th>"
        for c in 2:ncols
            fmtd = format_diff( before=prer[c], after=postr[c] )
            cell = "<td style='text-align:right'>$(fmtd.after_s)</td>
                    <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>"
            row *= cell
        end # cols
        row *= "</tr>"
        table *= row
    end # rows
    table *= "</tbody></table>"
    return table
end # frame to table


# TOLIBRARY
function results_to_html( 
    results      :: LegalAidOutput ) :: NamedTuple
    # table expects a tuple
    k = "$(LegalAidData.PROBLEM_TYPES[1])-$(LegalAidData.ESTIMATE_TYPES[2])"
    crosstab = format_crosstab( results.crosstab_pers[1][k]; 
        caption="Changes to elgibility: all Scottish Adults (click table for breakdowns)" )
    crosstabtables = "<div>"
    ctno = 1
    pc = format_crosstab( results.crosstab_bu[ctno]; 
        caption="Benefit Units", 
        title="Entilemment - Benefit Units"  )
    pc = wraptable( "Counts of Benefit Units", pc )
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
                results.crosstab_pers[ctno][k];
                caption = "Estimated number of Scottish adults experiencing $prettyprob in a 3-year period, by eligibility type; estimate: $prettyest" ) 
            pc = wraptable( title, pc )
            crosstabtables *= pc
        end
    end
    crosstabtables *= "</div>"
    tgts = LegalAidOutput.LA_TARGETS
    t = tgts[1]
    countstable = frame_to_table(
        ;    
        pre_df = results.breakdown_pers[1][t],
        post_df = results.breakdown_pers[2][t],
        caption =  "Eligibility Counts, all Scottish adults, by Employment (click table for more)." )
    
    allcounts =  "<div class='row'><div class='col'><h3>Breakdowns By Characteristics</h3></div></div>"
    for t in tgts[2:end]
        prett = Utils.pretty(t)
        allcounts *= "<div class='row'><div class='col'><h3>Breakdown Type: $prett</h3></div></div>"
        allcounts *= "<div class='row'><div class='col table-responsive'><h4>Personal Level</h4></div></div>"
        allcounts *= frame_to_table(
            ;    
            pre_df = results.breakdown_pers[1][t],
            post_df = results.breakdown_pers[2][t],
            caption =  "Eligibility Counts of all Scottish adults, by $prett." )
        allcounts *= "<div class='row'><div class='col'><h4>Assessment Unit Level</h4></div></div>"
        allcounts *= frame_to_table(
            ;    
            pre_df = results.breakdown_bu[1][t],
            post_df = results.breakdown_bu[2][t],
            caption =  "Eligibility Counts of assessment units, by $prett of the head of the unit." )
        allcounts *= "</div></div>"
    end
    allcounts *= "</div>"    
    
    casestable = frame_to_table(
            ;    
            pre_df = results.cases_pers[1][t],
            post_df = results.cases_pers[2][t],
            caption =  "Costs, all Scottish adults, by Employment and Problem Type(click table for more)." )
            allcosts = "<div class='row'><div class='col'><h3>Costs By Characteristics</h3></div></div>"
    
    allcases= "<div class='row'><div class='col'><h3>Cases By Characteristics</h3></div></div>"
    for t in tgts[2:end]
        prett = Utils.pretty(t)
        allcases *= "<div class='row'><div class='col'><h3>Breakdown Type: $prett</h3></div></div>"
        allcases *= "<div class='row'><div class='col table-responsive'><h4>Personal Level</h4></div></div>"
        allcases *= frame_to_table(
            ;    
            pre_df = results.cases_pers[1][t],
            post_df = results.cases_pers[2][t],
            caption =  "Cases, all Scottish people, by $prett and case type." )
        allcases *= "</div></div>"
    end
    allcases *= "</div>"    
    # cases_pers :: Vector{AbstractDict}
    # costs_pers :
    coststable = frame_to_table(
            ;    
            pre_df = results.costs_pers[1][t],
            post_df = results.costs_pers[2][t],
            caption =  "Costs, all Scottish people, by Employment and Problem Type(click table for more)." )
            allcosts = "<div class='row'><div class='col table-responsive'><h3>Costs By Characteristics</h3></div></div>"
    
    allcosts= "<div class='row'><div class='col'><h3>Cases By Characteristics</h3></div></div>"
    for t in tgts[2:end]
        prett = Utils.pretty(t)
        allcosts *= "<div class='row'><div class='col'><h3>Breakdown Type: $prett</h3></div></div>"
        allcosts *= "<div class='row'><div class='col table-responsive'><h4>Personal Level</h4></div></div>"
        allcosts *= frame_to_table(
            ;    
            pre_df = results.costs_pers[1][t],
            post_df = results.costs_pers[2][t],
            caption =  "Costs, by $prett and case type." )
        allcosts *= "</div></div>"
    end
    allcosts *= "</div>"    


    (; crosstab, crosstabtables, countstable, allcounts, coststable, allcosts, casestable, allcases )
end

function results_to_html( 
    results      :: AllLegalOutput ) :: NamedTuple
    civil = results_to_html( results.civil )
    aa  = results_to_html( results.aa )
    (; aa, civil )
end