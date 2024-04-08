# Genie_17325766451700233843 

function func_22411cac523203c6559c4153e5c1a3222f077530(;
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
                        q__table(
                            htmlsourceindent = "4",
                            ;
                            NamedTuple{(
                                Symbol("v-model"),
                                Symbol("row-key"),
                                Symbol(":columns"),
                                Symbol(":data"),
                            )}((
                                "emptable",
                                "__id",
                                "emptable.columns",
                                "emptable.data",
                            ))...,
                        );
                    ]
                end
            ]
        end
        """func_baa799b4638b4174e1acf09cf8b5830cedc4297d"""
    ]
end
