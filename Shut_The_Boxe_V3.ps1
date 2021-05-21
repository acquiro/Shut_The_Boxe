﻿#Reset the tiles
function New_play_table {
    Param
    (
        [parameter(Mandatory=$true,
        ParameterSetName="board_size")]
        [int]$board_size
    )
    
    1..12 | % {Remove-Variable -Name "tile_$_" -Scope global -ErrorAction SilentlyContinue} 

    1..$board_size | % {New-Variable -Name "tile_$_" -Value  "| $_ |" -Scope global}

}

#Dice Throw
function Get-AsciiDice {
    Param
    (
        [parameter(Mandatory=$true,
        ParameterSetName="Random")]
        [int]$Random
    )
    $result_throw = [pscustomobject]@{ Dice = "" ; Value = "" }

    $sum = 0 
    $NumberSet = (1..$random | foreach {Get-Random -Maximum 7 -Minimum 1 })
    $NumberSet | % {$sum += $_}
    $result_throw.Value = $sum
    $NumberSet | foreach { if ($_ -gt '6'){Write-Error -Message "Only supports digits 1-6" -ErrorAction Stop} }
  
    $d = @{
        1 = '     ','  o  ','     '
 
        2 = '   o ','     ',' o   '
        
        3 = ' o   ','  o  ','   o '
        
        4 = 'o   o','     ','o   o'
        
        5 = 'o   o','  o  ','o   o'
        
        6 = 'o   o','o   o','o   o'
    }
 
    $result_throw.Dice
    $a += (" _____   " * $NumberSet.Count) 
    $b = @()
     0..2 | ForEach-Object {
        foreach($n in $NumberSet) {
            $b+= "|$($d[$n][$_])|  " 
        }
    }
    $c = (" -----   " * $NumberSet.Count) 
    if ($NumberSet.Count -eq 3){
        $result_throw.Dice = $a,($b[0]+$b[1]+$b[2]),($b[3]+$b[4]+$b[5]),($b[6]+$b[7]+$b[8]),$c
    }
    elseif ($NumberSet.Count -eq 2){
        $result_throw.Dice = $a,($b[0]+$b[1]),($b[2]+$b[3]),($b[4]+$b[5]),$c
    }

    else {
        $result_throw.Dice = $a,$b[0],$b[1],$b[2],$c
    }

    return $result_throw
}

#Ugly GUI 
function Play_table {

    [System.Collections.ArrayList]$available_tiles = (Get-Variable tile_*).Value | % {[int]($_.Split(" ")| select -Index 1)}
    $available_tiles.sort()
    $number_of_tiles = $available_tiles.count
    $first_line = " "
    $second_line = ""
    $third_line = ""
    $forth_line = ""
    foreach ($tile in $available_tiles){
        if ($tile -gt 9){
        $first_line = $first_line+"____   " 
        $second_line = "$second_line|    | " 
        $j = $i+1
        [string]$third_line =  [string]$third_line +[string]((get-variable "tile_$tile" -ErrorAction SilentlyContinue).Value) + " "
        $forth_line = "$forth_line|____| "
        }
    
        else {
        $first_line = $first_line+"___   " 
        $second_line = "$second_line|   | " 
        $j = $i+1
        [string]$third_line =  [string]$third_line +[string]((get-variable "tile_$tile" -ErrorAction SilentlyContinue).Value) + " "
        $forth_line = "$forth_line|___| "
        }
    }
    

    
$boxe =@($first_line,
$second_line,
$third_line,
$forth_line)


    $global:playground = $boxe 
    #return $global:playground
}   

#Get All Available Combinations
function Get-Combinations {
    Param(
        [int] $SumToReach,
        [int[]]$NumbersToUse
    )

    $available_solutions = @()
    $NumbersToUse | ForEach-Object {
        $TheNumber = $_
        if ($TheNumber -eq $SumToReach) {
            $TheNumber
        } 
        elseif ($TheNumber -lt $SumToReach) {
            Get-Combinations -SumToReach ($SumToReach - $TheNumber) -NumbersToUse @($NumbersToUse | 
                Where-Object { $_ -gt $TheNumber }) |
                ForEach-Object { 
                    $available_solutions+= "$TheNumber+$($_ -join ',')"
                }
        }
    }
    return $available_solutions
}
 
#Main menue
function Start-Shut_The_Boxe {
    param(
    [Parameter(Mandatory)]
        [ValidateSet(2,3,4,5,6)]
        [int]$number_of_players,

    [Parameter()]
        [ValidateSet(9,10,11,12)]
        [int]$table_size = 9
    )

    scoreboard($number_of_players)
    Start-Play_Round -table_size $table_size
}

#Create the scoreboard
function Scoreboard ($number_of_players){

    $global:scoreboard = @()
    $global:scoreboard += 1..$number_of_players | % { [pscustomobject]@{ Player = "Player_$_" ; Current_Score = 0 ; Round_Won = 0} }

}

function Start-Play_Round{
    Param
    (
        [Parameter(Mandatory)]
        [int]$table_size
    )

    for ($i = 0 ; $i -lt ($global:scoreboard.count) ; $i++){
    
        new_play_table -board_size $table_size
        play_table
        while ((Get-Variable tile_*).count -gt 0){
        
                if ((Get-Variable tile_*)  | Where-Object { ($_.Name -Match "[1][0-2]")}) { 
                    $number_of_dice = 0
                    while (($number_of_dice -ne 2) -and ($number_of_dice -ne 3)){ 
                        $number_of_dice = Read-Host "Tiles above 9 are left, roll [2] or [3] dices "
                    }
                    $result_throw = Get-AsciiDice -random $number_of_dice
                }
                elseif  ((Get-Variable tile_*)  | Where-Object {($_.Name -Match "[6-9]")}) {
                      $result_throw = Get-AsciiDice -Random 2                 
                }
                else {
                    $number_of_dice = 0
                    while (($number_of_dice -ne 1) -and ($number_of_dice -ne 2)){ 
                        $number_of_dice = Read-Host "Only tiles under 6 are left, roll [1] or [2] dices "
                    }
                    $result_throw = Get-AsciiDice -random $number_of_dice
                }

                [int[]]$available_tiles = (Get-Variable tile_* -ValueOnly | % { $_.split(" ") | select -index 1})
                $possibilities = Get-Combinations -SumToReach $result_throw.Value -NumbersToUse $available_tiles

                $playground
                Write-Host ""
                $result_throw.Dice

                if ($possibilities -eq $null){
                    Write-Host "No possible combination left"
                    Write-Host "End of $($Global:scoreboard[$i].Player) round"
                    $player_score = 0
                    $available_tiles | % { $player_score += $_}
                    $scoreboard[$i].Current_Score += $player_score
                    Get-Variable tile_* | Remove-Variable    
                    Write-Host "$($Global:scoreboard[$i].Player) score = $($Global:scoreboard[$i].CurrentScore)"
                    Read-Host "Press any key to continue"
                } 
                else {
                    $cheat = read-Host "Open cheat sheet [Y] / [N]"
                    if (($cheat -eq 'Y') -or ($cheat -eq 'yes')){ 
                        Write-Host "`n`nPossible combinations :"
                        $possibilities
                    }
                    
                    [System.Collections.ArrayList]$temp_tiles = $available_tiles
                    $player_selection = 0
                    $selection_history = @()

                    while ($player_selection -ne $result_throw.Value){
                        [int]$selected_tile = Read-Host "Select tile one by one" 
                        if ($temp_tiles -contains $selected_tile){
                            $temp_tiles.Remove($selected_tile)
                            $player_selection += $selected_tile
                            $selection_history += [string]$selected_tile
                            Write-Host "Selected total = $player_selection / $($result_throw.Value)"
                        }

                        if ($player_selection -gt $result_throw.Value){
                            Write-Host "Selected tiles doesn't match throw value"
                            $reset = Read-Host "[R]eset selected tiles or [E]nd turn"
                            if (($reset -like "R" ) -or ($reset -like "reset"))  {
                                $player_selection = 0
                                $selection_history = @()
                                [System.Collections.ArrayList]$temp_tiles = $available_tiles
                                clear
                            } 
                            else {
                                $player_selection = $result_throw.Value
                                $player_score = 0
                                $temp_tiles | % { $player_score += $_}
                                $scoreboard[$i].Current_Score += $player_score
                                Get-Variable tile_* | Remove-Variable
                            }
                        
                        }
                    
                    }
                    $selection_history | % {
                    [string]$to_remove = "tile_$_"
                    Remove-Variable $to_remove
                    Play_table
                    clear
                    if ((Get-Variable tile_*).count -eq 0){
                        Write-Host "Shut the boxe !!! You win this round!"
                        $global:scoreboard[$i].Round_Won += 1
                        $global:scoreboard[0..($global:scoreboard.count)] | % {$_.Score = 0 }
                    }
                }
            }   
        }
    }
    clear
    $round_winner =  $scoreboard | Sort-Object -Property Current_Score | select -First 1 
    Write-Host "$($round_winner.Player) win this round with $($round_winner.Current_Score) points"   
    $scoreboard | Sort-Object -Property Current_Score | select -First 1 | % {$_.Round_Won += 1}
    $scoreboard
    $scoreboard | % {$_.Current_Score = 0}   
    $new_round = Read-Host "Another round ?  [Y]es / [N]o"
    if (($new_round -eq 'Y') -or ($new_round -eq 'yes')){ 
        Start-Play_Round -table_size $table_size
    }
}
                