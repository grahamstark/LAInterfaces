
const TYP_LABELS = Dict(
    [
        "Elig" => "Eligibility",
        "Cases" => "Numbers of Cases",
        "Costs"=> "Gross Costs (£000s p.a.)"
    ])

const PRE_POST = Dict(
    ["Pre" => "Base Case", "Post"=>"After Your Changes"]
)

function insert_sheet!( xf, 
    typ::String, 
    prepost::String, 
    tables :: Dict )
    @debug "adding sheet $typ $prepost"
    sheet = XLSX.addsheet!( xf )
    sheetname = "$typ - $prepost"
    XLSX.rename!( sheet, sheetname )
    row = 1
    for bd in LegalAidOutput.LA_TARGETS
        tab = tables[bd]
        nrows, ncols = size(tab)
        caption = "$(TYP_LABELS[typ]), broken down by $bd, $(PRE_POST[prepost])"
        sheet["A$row"] = caption
        enum_to_string!( tab ) # TRANSLate enums tp strings; xslx doesn't do enums
        row += 2
        XLSX.writetable!( sheet, tab; anchor_cell=XLSX.CellRef("A$row"))
        row += nrows+2
    end
end

function export_xlsx( results :: LegalOutput )::String 
    filename = String( rand( 'a':'z', 20 ))*".xlsx"
    urlname = joinpath(  "scratch", filename )
    filename = joinpath(  "web", urlname )
    XLSX.openxlsx(filename, mode="w") do xf
        sheet = xf[1]
        XLSX.rename!( sheet, "Eligibility Crosstabs")
        sheet["A1"] = "Eligibility Crosstab, all people, inc. children"
        XLSX.writetable!( sheet, 
            crosstab_to_frame(
                results.crosstab_pers[1]);
                anchor_cell=XLSX.CellRef("A3"))  

        sheet["A10"] = "Eligibility Crosstab, adults only"
        XLSX.writetable!( sheet, 
        crosstab_to_frame(
            results.crosstab_adults[1]);
            anchor_cell=XLSX.CellRef("A12"))  

        sheet["A19"] = "Eligibility Crosstab, adults only"
        XLSX.writetable!( sheet, 
        crosstab_to_frame(
            results.crosstab_bus[1]);
            anchor_cell=XLSX.CellRef("A21"))  
                # sheetname="Person Crosstab")        

        sheet["A29"] = "Kieren's Summary Table"
           XLSX.writetable!( sheet,                
                   results.summary_tables[1];
                   anchor_cell=XLSX.CellRef("A31"))  
              
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