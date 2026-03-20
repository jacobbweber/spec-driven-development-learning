@{
    # Static Analysis Best Practices
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingWriteHost'
        'PSUseApprovedVerbs'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseSingularNouns'
        'PSAvoidDefaultValueForMandatoryParameter'
        'PSAvoidGlobalVars'
        
        # Added Best Practices
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingDoubleQuotesForConstantString'
        'PSAvoidUsingPositionalParameters'
        'PSUseShouldProcessForStateChangingFunctions'
        'PSUseUsingScopeModifierInNewRunspaces'
        'PSAvoidTrailingWhitespace'
        'PSUseConsistentWhitespace'
        'PSUseConsistentIndentation'
    )

    # Exclude certain rules if necessary
    ExcludeRules = @()

    # Rule Configuration (e.g., OTBS formatting)
    Rules = @{
        PSPlaceCloseBrace = @{
            Enable = $true
            IgnoreOneLineBlock = $true
            NewLineAfter = $true
        }
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
    }
}
