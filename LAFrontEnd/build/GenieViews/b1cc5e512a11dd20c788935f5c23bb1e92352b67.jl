# Genie_16969611192636489097 

function func_c960b86aa1900c59e18d8e7cf115a7192ff293ab(; context = Genie.Renderer.vars(:context),model = Genie.Renderer.vars(:model)) 

          [
          
Genie.Renderer.Html.div(class="row" , htmlsourceindent="2"  ) do;[
Genie.Renderer.Html.div(class="st-col col" , htmlsourceindent="3"  ) do;[
Genie.Renderer.Html.h1(htmlsourceindent="4"  ) do;[
"""LEGAL AID""" ;  ]end
 ;  ]end
 ;  ]end

Genie.Renderer.Html.div(class="row" , htmlsourceindent="2"  ) do;[
Genie.Renderer.Html.div(class="st-col col" , htmlsourceindent="3"  ) do;[
Genie.Renderer.Html.span(htmlsourceindent="4"  ) do;[
"""Other Dependants Allowance (£p.a):""" ;  ]end

q__slider(htmlsourceindent="4" , ; NamedTuple{(Symbol("v-model"), Symbol(":step"), Symbol(":min"), Symbol(":max"))}(("other_dependants_allowance", "10.0", "0.0", "20000.0"))... )
Genie.Renderer.Html.p(htmlsourceindent="4"  ) do;[
"""other_dependants_allowance: """
Genie.Renderer.Html.b(htmlsourceindent="5"  ) do;[
"""£{{other_dependants_allowancepw}}""" ;  ]end

""" p.a.""" ;  ]end
 ;  ]end

Genie.Renderer.Html.div(class="st-col col" , htmlsourceindent="3"  ) do;[
"""HTML{String}[HTML{String}("{{crosstab}}")]""" ;  ]end
 ;  ]end

"""HTTP.Messages.Response:
"""
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

{{crosstab}}""" """
          ]
          end
          