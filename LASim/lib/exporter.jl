using 

function export( results :: LegalOutput )
    filename = String(rand( 'a':'z',12))*".xlsx"
    filename = joinpath( "tmp",filename)
    XLSX.openxlsx(filename, mode="w") do xf
    i = 0
    for i in 1:20
        sheet = xf[1]
        if i > 1 
            sheet = XLSX.addsheet!(xf)
        end
        name = "SHEET #$i"
        df = randframe( name )
        XLSX.rename!( sheet, name )
        XLSX.writetable!( sheet, randframe( name ))
    end # for 
    end # xlsx do
end