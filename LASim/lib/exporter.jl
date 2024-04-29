
const TYP_LABELS = Dict(
    [
        "Elig" => "Eligibility",
        "Cases" => "Numbers of Cases",
        "Costs"=> "Gross Costs (£000s p.a.)"
    ])

const PRE_POST = Dict(
    ["Pre" => "Base Case", "Post"=>"After Your Changes"]
)

function insert_sheet!( xf, typ, bd, prepost, df :: DataFrame )
    @show "adding sheet $typ $bd $prepost"
    sheet = XLSX.addsheet!( xf )
    sheetname = "$typ $bd $prepost"
    caption = "$(TYP_LABELS[typ]), broken down by $bd, $(PRE_POST[prepost])"
    XLSX.rename!( sheet, sheetname )
    nrows, ncols = size(df)
    row = 1
    sheet["A$row"] = caption
    enum_to_string!( df ) # TRANSLate enums tp strings; xslx doesn't do enums
    row += 2
    XLSX.writetable!( sheet, df; anchor_cell=XLSX.CellRef("A$row"))
    row += nrows+1
    sheet["A$row"] = caption
    row += 2
    XLSX.writetable!( sheet, df; anchor_cell=XLSX.CellRef("A$row"))
    
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
        for t in LegalAidOutput.LA_TARGETS
            insert_sheet!( xf, "Elig", t, "Pre", results.breakdown_pers[1][t])
            insert_sheet!( xf, "Elig", t, "Post", results.breakdown_pers[2][t])
            insert_sheet!( xf, "Cases", t, "Pre", results.cases_pers[1][t])
            insert_sheet!( xf, "Cases", t, "Post", results.cases_pers[2][t])
            insert_sheet!( xf, "Costs", t, "Pre", results.costs_pers[1][t])
            insert_sheet!( xf, "Costs", t, "Post", results.costs_pers[2][t])
        end # for 
    end # xlsx do
    return urlname
end

function export_xlsx( 
    results :: AllLegalOutput )::NamedTuple
    civxlsx = export_xlsx( results.civil )
    aaxlxs = export_xlsx( results.aa )
    (; civxlsx, aaxxlsx)
end