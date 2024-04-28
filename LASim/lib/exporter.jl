
function insert_sheet!( xf, name :: String, df :: DataFrame )
    sheet = XLSX.addsheet!( xf )
    XLSX.rename!( sheet, name )
    enum_to_string!( df )
    XLSX.writetable!( sheet, df )
end

function export_xlsx( results :: LegalOutput )::String 
    filename = String( rand( 'a':'z', 20 ))*".xlsx"
    urlname = joinpath(  "scratch", filename )
    filename = joinpath(  "web", urlname )
    XLSX.openxlsx(filename, mode="w") do xf
        XLSX.writetable!( xf[1], 
            crosstab_to_frame(
                results.crosstab_pers[1]))  
           # sheetname="Person Crosstab")
        for t in LegalAidOutput.LA_TARGETS
            insert_sheet!( xf, "Elig Counts, $t pre", results.breakdown_pers[1][t])
            insert_sheet!( xf, "Elig Counts,  $t post", results.breakdown_pers[2][t])
            insert_sheet!( xf, "Cases, $t pre", results.cases_pers[1][t])
            insert_sheet!( xf, "Cases, $t post", results.cases_pers[2][t])
            insert_sheet!( xf, "Costs,  $t pre", results.costs_pers[1][t])
            insert_sheet!( xf, "Costs,  $t post", results.costs_pers[2][t])
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