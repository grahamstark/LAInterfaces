
"
" use like vim -e [file] < m2pas.vim
" Graham 19/01/2002
"
"
%s/DISCRESIONARY_HOUSING_PAYMENT/DISCRETIONARY_HOUSING_PAYMENT/g
%s/SCOTTISH_CARERS_SUPPLEMENT/CARERS_ALLOWANCE_SUPPLEMENT/g
%s/SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING/CHILD_DISABILITY_PAYMENT_CARE/g
%s/SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY/CHILD_DISABILITY_PAYMENT_MOBILITY/g
%s/SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE/PENSION_AGE_DISABILITY/g
%s/SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING/ADP_DAILY_LIVING/g
%s/SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY/ADP_MOBILITY/g

:write
:quit
