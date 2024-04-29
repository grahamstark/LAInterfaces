
const TYP_LABELS = Dict(
    [
        "Elig" => "Eligibility",
        "Cases" => "Numbers of Cases",
        "Costs"=> "Gross Costs (£000s p.a.)"
    ])

const PRE_POST = Dict(
    ["Pre" => "Base Case", "Post"=>"After Your Changes"]
)

function insert_sheet!( xf, typ, prepost, df :: Dict )
    @show "adding sheet $typ $prepost"
    sheet = XLSX.addsheet!( xf )
    sheetname = "$typ $prepost"
    XLSX.rename!( sheet, sheetname )
    nrows, ncols = size(df)
    row = 1
    for bd in LegalAidOutput.LA_TARGETS
        caption = "$(TYP_LABELS[typ]), broken down by $bd, $(PRE_POST[prepost])"
        sheet["A$row"] = caption
        enum_to_string!( df ) # TRANSLate enums tp strings; xslx doesn't do enums
        row += 2
        XLSX.writetable!( sheet, df[bd]; anchor_cell=XLSX.CellRef("A$row"))
        row += nrows+2
    end
end

function export_xlsx( results :: LegalOutput )::String 
    filename = String( rand( 'a':'z', 20 ))*".xlsx"
    urlname = joinpath(  "scratch", filename )
    filename = joinpath(  "web", urlname )
    XLSX.openxlsx(filename, mode="w") do xf
        sheet = xf[1]
        XLSX.rename!( sheet, "Eligibility Crosstab")
        sheet["A1"] = "Eligibility Crosstab, all people, inc. children"
        XLSX.writetable!( sheet, 
            crosstab_to_frame(
                results.crosstab_pers[1]);
                anchor_cell=XLSX.CellRef("A3"))  
           # sheetname="Person Crosstab")        
        insert_sheet!( xf, "Elig", "Pre", results.breakdown_pers[1])
        insert_sheet!( xf, "Elig", "Post", results.breakdown_pers[2])
        insert_sheet!( xf, "Cases", "Pre", results.cases_pers[1])
        insert_sheet!( xf, "Cases", "Post", results.cases_pers[2])
        insert_sheet!( xf, "Costs", "Pre", results.costs_pers[1])
        insert_sheet!( xf, "Costs", "Post", results.costs_pers[2])
    end # xlsx do
    return urlname
end

function export_xlsx( 
    results :: AllLegalOutput )::NamedTuple
    civxlsx = export_xlsx( results.civil )
    aaxlxs = export_xlsx( results.aa )
    (; civxlsx, aaxxlsx)
end