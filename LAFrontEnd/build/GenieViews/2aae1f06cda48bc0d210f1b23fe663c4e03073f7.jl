# Genie_10595399632322175554 

function func_5ec59fbf8d989c2b2b894db5c98dac23656cf814(;
    context = Genie.Renderer.vars(:context),
    model = Genie.Renderer.vars(:model),
)

    [
        Genie.Renderer.Html.div(class = "row", htmlsourceindent = "2") do
            [
                Genie.Renderer.Html.div(class = "st-col col", htmlsourceindent = "3") do
                    [
                        Genie.Renderer.Html.h1(htmlsourceindent = "4") do
                            [
                                """LEGAL AID""";
                            ]
                        end;
                    ]
                end;
            ]
        end
        Genie.Renderer.Html.div(class = "row", htmlsourceindent = "2") do
            [
                Genie.Renderer.Html.div(class = "st-col col", htmlsourceindent = "3") do
                    [
                        Genie.Renderer.Html.span(htmlsourceindent = "4") do
                            [
                                """Other Dependants Allowance (£p.a):""";
                            ]
                        end
                        q__slider(
                            htmlsourceindent = "4",
                            ;
                            NamedTuple{(
                                Symbol("v-model"),
                                Symbol(":step"),
                                Symbol(":min"),
                                Symbol(":max"),
                            )}(("other_dependants_allowance", "10.0", "0.0", "20000.0"))...,
                        )
                        Genie.Renderer.Html.p(htmlsourceindent = "4") do
                            [
                                """other_dependants_allowance: """
                                Genie.Renderer.Html.b(htmlsourceindent = "5") do
                                    [
                                        """£{{other_dependants_allowancepw}}""";
                                    ]
                                end
                                """ p.a."""
                            ]
                        end
                    ]
                end
                Genie.Renderer.Html.div(class = "st-col col", htmlsourceindent = "3") do
                    [
                        """HTML{String}[HTML{String}("{{crosstab}}")]""";
                    ]
                end
            ]
        end
        """{{crosstab}}"""
    ]
end
