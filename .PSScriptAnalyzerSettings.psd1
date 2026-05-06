@{
    # Repository-level PSScriptAnalyzer settings.
    # Disable the approved-verbs rule because embedded XAML control names
    # can trigger false positives (GUI uses friendly control names).
    Rules = @{
        PSUseApprovedVerbs = @{ Enable = $false }
    }
}
