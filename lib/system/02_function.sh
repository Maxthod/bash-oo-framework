Function.Exists(){
    local name="$1"
    local typeMatch=$(type "$name" 2> /dev/null) || return 1
    echo "$typeMatch" | grep "function\|alias" &> /dev/null || return 1
    return 0
}
alias Object.Exists="Function.Exists"

Function.AssignParamLocally() {
    local commandWithArgs=( $1 )
    local command="${commandWithArgs[0]}"

    shift

    if [[ "$command" == "trap" || "$command" == "l="* || "$command" == "_type="* ]]
    then
        paramNo+=-1
        return 0
    fi

    if [[ "$command" != "local" ]]
    then
        assignNormalCodeStarted=true
    fi

    local varDeclaration="${commandWithArgs[1]}"
    if [[ $varDeclaration == '-'* ]]
    then
        varDeclaration="${commandWithArgs[2]}"
    fi
    local varName="${varDeclaration%%=*}"

    # var value is only important if making an object later on from it
    local varValue="${varDeclaration#*=}"

    if [[ ! -z $assignVarType ]]
    then
        local previousParamNo=$(($paramNo - 1))

        if [[ "$assignVarType" == "array" ]]
        then
            # passing array:
            execute="$assignVarName=( \"\${@:$previousParamNo:$assignArrLength}\" )"
            eval "$execute"
            paramNo+=$(($assignArrLength - 1))

            unset assignArrLength
        elif [[ "$assignVarType" == "params" ]]
        then
            execute="$assignVarName=( \"\${@:$previousParamNo}\" )"
            eval "$execute"
        elif [[ "$assignVarType" == "reference" ]]
        then
            execute="$assignVarName=\"\$$previousParamNo\""
            eval "$execute"
        elif [[ ! -z "${!previousParamNo}" ]]
        then
            execute="$assignVarName=\"\$$previousParamNo\""
            eval "$execute"
        fi
    fi

    assignVarType="$__capture_type"
    assignVarName="$varName"
    assignArrLength="$__capture_arrLength"
}

Function.CaptureParams() {
    __capture_type="$_type"
    __capture_arrLength="$l"
}

alias @trapAssign='Function.CaptureParams; trap "declare -i \"paramNo+=1\"; Function.AssignParamLocally \"\$BASH_COMMAND\" \"\$@\"; [[ \$assignNormalCodeStarted = true ]] && trap - DEBUG && unset assignVarType && unset assignVarName && unset assignNormalCodeStarted && unset paramNo" DEBUG; '
alias @param='@trapAssign local'
alias @reference='_type=reference @trapAssign local -n'
alias @var='_type=var @param'
alias @int='_type=int @trapAssign local -i'
alias @params='_type=params @param'
alias @array='_type=array @param'
