#=
struct Expense{T}
is_flat :: Bool
v       :: T
max     :: T
end
 
housing               = Expense( false, one(T), inplaceoftypemax(T))
    debt_repayments       = Expense( false, one(T), inplaceoftypemax(T))
    childcare             = Expense( false, one(T), inplaceoftypemax(T))
    work_expenses         = Expense( false, one(T), inplaceoftypemax(T))
    maintenance           = Expense( false, one(T), inplaceoftypemax(T))
    repayments            = Expense( false, one(T), inplaceoftypemax(T))
end

# index: parse
income_living_allowance: parseFloat($( "#income_living_allowance" ).val()),
net_physical_wealth: $('#net_physical_wealth').is(':checked'),

# index: field
<fieldset class="col border text-black m-1 p-2">
<legend class="text-primary">Passported Benefits</legend>
<div class="form-check">
    <input class="form-check-input INCOME_SUPPORT_passported" type="checkbox" value="" id="INCOME_SUPPORT_passported" checked="checked"/>
    <label class="form-check-label INCOME_SUPPORT_passported" for="INCOME_SUPPORT_passported">
        Income Support
    </label>
  </div>

# subsys 
  net_financial_wealth :: Bool
  net_physical_wealth :: Bool
  net_housing_wealth :: Bool    
  income_living_allowance :: T    

# subsys: load from 

# load to 

sys.income_partners_allowance         = pars.income_partners_allowance/WEEKS_PER_YEAR
sys.income_other_dependants_allowance = pars.income_other_dependants_allowance/WEEKS_PER_YEAR

=#

using Unicode

"""
a_string_or_symbol_like_this => "A String Or Symbol Like This"
"""
function pretty(a)
   s = string(a)
   s = strip(lowercase(s))
   s = replace(s, r"[_]" => " ")
   Unicode.titlecase(s)
end

const items = ["housing", "childcare","work_expenses","maintenance","repayments"]

const elems = ["is_flat","v","max"]

jsload = ""

fields = ""

subsys = ""

subload = ""

mainload = ""

formload = ""

expenses_set = ""

for item in items
    global jsload
    global fields
    global subsys
    global subload
    global mainload
    global formload
    global expenses_set 

    isflatkey = "$(item)_is_flat"
    vkey = "$(item)_v"
    maxkey = "$(item)_max"
    vlabelkey = "$(item)_vlabel"
    label = pretty( item )

    expenses_set *= """
    setExpenseFields( "$(item)", false );
    """

    jsload *= """

    $(isflatkey): \$('#$(isflatkey)').is(':checked'),
    $(vkey): parseFloat(\$('#$(vkey)').val()),
    $(maxkey): parseFloat(\$('#$(maxkey)').val()),

    """


    fields *= """

    <fieldset class="col border text-black m-1 p-2">
    <legend class="text-primary">$(label)</legend>
    <div>
        <input onchange='setExpenseFields( "$(item)", true )' class='form-check-input ' type='checkbox' id='$(isflatkey)' />
        <label class='form-check-label $(isflatkey)' for='$(isflatkey)'>
            Treat as Flat Rate?
        </label>
        <br/>
        <label for='$(vkey)' id='$vlabelkey'  class='form-label'>% Applicable or Absolute amount (£)</label>
        <input id='$(vkey)' type='number' name="$(vkey)" min='0' max='2000' value='' step='0.01' size="8" class='form-control w-50'/>
        <label for='$(maxkey)' class='form-label'>Maximum Amount (£)</label>
        <input id='$(maxkey)' type='number' name="$(maxkey)" min='0' max='99999999999' value='' step='1' size="8" class='form-control w-50'/>
    </div>
    </fieldset>
    """

    subsys *= """
    $isflatkey :: Bool
    $vkey :: T
    $maxkey :: T

    """

    subload *= """
    sys.expenses.$(item).is_flat,
    sys.expenses.$(item).v,
    sys.expenses.$(item).max,

    """

    mainload *= """
    sys.expenses.$(item) = Expense( pars.$(isflatkey), pars.$(vkey), pars.$(maxkey) )
    """

    formload *= """
    setCheck(
        "$(isflatkey)",
        params.$(isflatkey),
        defaults.$(isflatkey) );
    setVal( "$(vkey)", params.$(vkey), defaults.$(vkey) );
    setVal( "$(maxkey)", params.$(maxkey), defaults.$(maxkey) );

    """

end

println( jsload )
println( fields )
println( subsys )
println( subload )
println( mainload )
println( formload )
println( expenses_set )