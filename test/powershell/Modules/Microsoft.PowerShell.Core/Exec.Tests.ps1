# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe 'Switch-Process tests for Unix' -Tags 'CI' {
    BeforeAll {
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if (-not [ExperimentalFeature]::IsEnabled('PSExec') -or $IsWindows)
        {
            $PSDefaultParameterValues['It:Skip'] = $true
            return
        }
    }

    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }

    It 'Exec alias should map to Switch-Process' {
        $alias = Get-Command exec
        $alias | Should -BeOfType [System.Management.Automation.AliasInfo]
        $alias.Definition | Should -BeExactly 'Switch-Process'
    }

    It 'Exec by itself does nothing' {
        exec | Should -BeNullOrEmpty
    }

    It 'Exec given a cmdlet should fail' {
        { exec Get-Command } | Should -Throw -ErrorId 'CommandNotFound,Microsoft.PowerShell.Commands.SwitchProcessCommand'
    }

    It 'Exec given an exe should work' {
        $id, $uname = pwsh -noprofile -noexit -outputformat text -command { $pid; exec uname }
        Get-Process -Id $id -ErrorAction Ignore| Should -BeNullOrEmpty
        $uname | Should -BeExactly (uname)
    }

    It 'Exec given an exe and arguments should work' {
        $id, $uname = pwsh -noprofile -noexit -outputformat text -command { $pid; exec uname -a }
        Get-Process -Id $id -ErrorAction Ignore| Should -BeNullOrEmpty
        $uname | Should -BeExactly (uname -a)
    }

    It 'Exec will replace the process' {
        $sleep = Get-Command sleep -CommandType Application | Select-Object -First 1
        $p = Start-Process pwsh -ArgumentList "-noprofile -command exec $($sleep.Source) 90" -PassThru
        Wait-UntilTrue {
            ($p | Get-Process).Name -eq 'sleep'
        } -timeout 60000 -interval 100 | Should -BeTrue
    }
}

Describe 'Switch-Process for Windows' {
    BeforeAll {
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if (-not $IsWindows)
        {
            $PSDefaultParameterValues['It:Skip'] = $true
            return
        }
    }

    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }

    It 'Switch-Process should not be available' {
        Get-Command -Name Switch-Process -ErrorAction Ignore | Should -BeNullOrEmpty
    }

    It 'Exec alias should not be available' {
        Get-Alias -Name exec -ErrorAction Ignore | Should -BeNullOrEmpty
    }
}
