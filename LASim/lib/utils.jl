function pix( s :: String, incs :: IncludedItems )
    println( "$s\n\n" )
    p = sort!(collect(incs.included))
    println("=== INCLUDED ====")
    for i in p
      println(i)
    end
    println("")
    p = sort!(collect(incs.deducted))
    println("=== DEDUCTED === ")
    for i in p
      println(i)
    end
    println("\n\n")
end
