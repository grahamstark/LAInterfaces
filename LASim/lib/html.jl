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

const CT_LABELS = [
    "Passported",
    "Fully Entitled", 
    "W/Contribution",
    "Not Entitled", 
    "Total"]

function format_crosstab( 
    crosstab :: Matrix; 
    examples :: AbstractArray,
    title="", 
    caption = "" ) :: AbstractString
    
    @argcheck size( crosstab ) == (5,5)
    

    t = """
    <table class='table table-hover'>
            <thead>
            <caption>$caption</caption>
            </thead>
            <tbody>
        """
        tr = "<tr><td></td><td colspan='5' style='text-align:center' class='justify-content-center'>Old System</td><tr><td rowspan='8' class='align-middle'>New System</td><tr><th></th>"
        for c in 1:5
            cell = "<th>$(CT_LABELS[c])</th>"
            tr *= cell
        end
        tr *= "</tr>"
        t *= tr
        for r in 1:5
            tr = """
                <tr><th>$(CT_LABELS[r])</th>
            """
            for c in 1:5
                v = fmt( crosstab[r,c] )
                colour = if( r == 5) && ( c == 5)
                    "table-primary"
                elseif(r == 5) || (c == 5) # totals
                    "table-debug"
                elseif r == c # on the diagonal
                    "table-primary"
                elseif r < c # above the diagonal
                    "table-success"
                else # below the diagonal
                    "table-danger"
                end
                cell = """
                <td class='text-right $colour' 
                    style='text-align:right'
                    data-bs-toggle='modal' 
                    data-bs-target='#example-popup-$r-$c'>$v</td>
                """
                #=
                cell = if length(examples[r,c]) > 0
                    """
                    <td class='text-right $colour' 
                        style='text-align:right'
                        data-bs-toggle='modal' 
                        data-bs-target='#example-popup-$r-$c'>$v</td>
                    """
                else
                    """
                    <td class='text-right $colour' 
                        style='text-align:right'>$v<td>
                    """
                end
                =#
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
    df :: DataFrame;
    up_is_good :: Vector{Int},
    prec :: Int = 0, 
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
        fmtd = format_diff( before=r[2], after=r[3], up_is_good=up_is_good[i], prec=prec )
        row_style = i == totals_col ? "class='text-bold table-debug' " : ""
        row = "<tr $row_style><th class='text-left'>$(r[1])</th>
                  <td style='text-align:right'>$(fmtd.before_s)</td>
                  <td style='text-align:right'>$(fmtd.after_s)</td>
                  <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

const FIRST_COL_RENAMES = Dict(
    ["Missing_ILO_Employment"=>"Children", 
     "Missing Ilo Employment"=>"Children", 
      Missing_ILO_Employment=>"Children"])

"""
"Missing_Marital_Status" => "Missing Marital Status", but
"Missing_ILO_Employment"=>"Children" since it's in FIRST_COL_RENAMES
"""
function first_col_rename( thing )::String
    return get( FIRST_COL_RENAMES, thing, Utils.pretty( thing ))
end

function aa_colname_rename( thing )::String
    return get( FIRST_COL_RENAMES, thing, Utils.pretty( thing ))
end

function civil_colname_rename( thing )::String
    return get( FIRST_COL_RENAMES, thing, Utils.pretty( thing ))
end

const CIVIL_TRANS = Dict(["Aa Total"=>"Total", "Adults With Incapacity Or Mental Health"=>"Adults with Incapacity"])
const AA_TRANS = Dict(["Aa Total"=>"Total", "Adults With Incapacity Or Mental Health"=>"Mental Health"])

function frame_to_table(
    ;
    pre_df  :: DataFrame,
    post_df :: DataFrame,
    caption :: String = "",
    systype :: SystemType )
    @argcheck size( pre_df ) == size( post_df )

    function translate( name :: String ) :: String
        translations = systype == sys_aa ? AA_TRANS : CIVIL_TRANS
        return get( translations, name, name )
    end
    
    @debug names( pre_df )
    colnames = Utils.pretty.( translate.(names( pre_df )))
    @debug colnames
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
        row_style = r == nrows ? "class='text-bold table-debug' " : ""
        rowlabel = r == nrows ? "Totals" : first_col_rename( prer[1] )
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

function crosstab_to_frame( crosstab :: Matrix ) :: DataFrame
    d = DataFrame()
    d.pre=CT_LABELS
    for col = 1:5
        colname = Symbol( CT_LABELS[col])
        d[!,colname] = crosstab[:,col]
    end
    d
end

function enum_to_string!( df :: DataFrame )
    col1=df[!,1]
    col1 = first_col_rename.(string.(col1))
    df[!,1] = col1
    df[end,1] = "Total"
end

# TOLIBRARY
function results_to_html( 
    results :: LegalOutput;
    la2 :: OneLegalAidSys,
    systype :: SystemType ) :: NamedTuple
    # table expects a tuple
    # k = "$(LegalAidData.PROBLEM_TYPES[1])-$(LegalAidData.ESTIMATE_TYPES[2])"
    crosstab = format_crosstab( 
        results.crosstab_adults[1];
        examples =  results.crosstab_adults_examples[1], 
        caption="Changes to elgibility: all Scottish Adults (click table for breakdowns)" )
    
    crosstab_examples = "<div>"
    for r in 1:5
        for c in 1:5
            if length(results.crosstab_adults_examples[1][r,c])  > 0
                examples = make_examples( 
                    results.crosstab_adults_examples[1][r,c], 
                    la2=la2 )
                k = "example-popup-$r-$c"
                from = CT_LABELS[c]
                to = CT_LABELS[r]
                crosstab_examples *= """
                <div class='modal fade' id='$(k)' tabindex='-1' role='dialog' aria-labelledby='crosstab-label' aria-hidden='true'>
                    <div class='modal-dialog modal-lg'  role='document'>
                        <div class='modal-content'>
                            <div class='modal-header'>
                                <h5 class='modal-title' id='crosstab-table-label'/>Examples of changes from $from -> $to</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div> <!-- header -->
                            <div class='modal-body'>
                                <div id='$(k)-content'>
                                    $(examples)
                                </div>
                            </div>
                        </div><!-- content -->
                    </div> <!--dialog -->
                </div> <!-- big-table modal -->
                """
            end # any examples
        end # cols
    end # rows
    crosstab_examples *= "</div>"
    tgts = LegalAidOutput.LA_TARGETS
    t = tgts[1]
    countstable = frame_to_table(
        ;    
        pre_df = results.breakdown_pers[1][t],
        post_df = results.breakdown_pers[2][t],
        caption =  "Eligibility Counts, all Scottish people, by Employment (click table for more).",
        systype = systype )
    
    allcounts =  "<div class='row'><div class='col'><h3>Breakdowns By Characteristics</h3></div></div>"
    for t in tgts[2:end]
        prett = Utils.pretty(t)
        allcounts *= "<div class='row'><div class='col'><h3>Breakdown Type: $prett</h3></div></div>"
        allcounts *= "<div class='row'><div class='col table-responsive'><h4>Personal Level</h4></div></div>"
        allcounts *= frame_to_table(
            ;    
            pre_df = results.breakdown_pers[1][t],
            post_df = results.breakdown_pers[2][t],
            caption =  "Eligibility Counts of all Scottish people, by $prett.",
            systype = systype  )
        allcounts *= "<div class='row'><div class='col'><h4>Assessment Unit Level</h4></div></div>"
        allcounts *= frame_to_table(
            ;    
            pre_df = results.breakdown_bu[1][t],
            post_df = results.breakdown_bu[2][t],
            caption =  "Eligibility Counts of assessment units, by $prett of the head of the unit.",
            systype = systype  )
        allcounts *= "</div></div>"
    end
    allcounts *= "</div>"    
    
    casestable = frame_to_table(
            ;    
            pre_df = results.cases_pers[1][t],
            post_df = results.cases_pers[2][t],
            caption =  "Costs, all Scottish people, by Employment and Problem Type(click table for more).",
            systype = systype )
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
            caption =  "Cases, all Scottish people, by $prett and case type.",
            systype = systype )
        allcases *= "</div></div>"
    end
    allcases *= "</div>"    
    # cases_pers :: Vector{AbstractDict}
    # costs_pers :
    coststable = frame_to_table(
            ;    
            pre_df = results.costs_pers[1][t],
            post_df = results.costs_pers[2][t],
            caption =  "Costs, all Scottish people, by Employment and Problem Type(click table for more).",
            systype = systype )
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
            caption =  "Costs, by $prett and case type.",
            systype = systype )
        allcosts *= "</div></div>"
    end
    allcosts *= "</div>"    
    summary_table = 
        frame_to_table(
            results.summary_tables[1];
            up_is_good = [0,0,1,0],
            prec = 0 )
    (; crosstab, crosstab_examples, countstable, allcounts, coststable, allcosts, casestable, allcases, summary_table )
end


function all_results_to_html( 
    results  :: AllLegalOutput, 
    legalaid :: ScottishLegalAidSys ) :: NamedTuple
    civil = results_to_html( results.civil, la2=legalaid.civil, systype=sys_civil )
    aa  = results_to_html( results.aa, la2=legalaid.aa, systype=sys_aa )
    (; aa, civil )
end