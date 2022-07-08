@cards = qw(1 2 3 4 5 6 7 8 9 10 J D K);
@suits = qw(h d s c);
@deck = ();
%card_points = map { $_ => $_ =~ /\d+/ ? $_ : 10 } @cards;

for $s (@suits) {
    for $c (@cards) {
        push @deck, "$c$s";
    }
}


sub shuffle_cards {
    my $deck = shift;
    my $i = @$deck;
    while ($i--) {
        my $j = int rand($i+1);
        @$deck[$i, $j] = @$deck[$j, $i];
    }
}

sub calculate_points {
    @c = @_;
    $points = 0;
    for (sort {(grep { substr($b, 0, -1) eq $cards[$_] } 0..$#cards)[0] <=> (grep { substr($a, 0, -1) eq $cards[$_] } 0..$#cards)[0] }  @c) {
        chop($_);
        if ($_ eq 1) {
            if ($points + 11 <= 21) {
                $points += 11;
            } else {
                $points += 1;
            }
        } else {
            $points += $card_points{$_};
        }
    }
    return $points;
}

@player_cards = ();
@dealer_cards = ();

$player_points = 0;
$dealer_points = 0;

$player_bet = 0;
$player_chips = 180;

$min_bet = 1;
$max_bet = 40;

while ($player_chips > 0) {
    $index = 0;
    shuffle_cards(\@deck);
    $player_bet = 0;

    while ($player_bet < $min_bet or $player_bet > $max_bet or $player_bet > $player_chips) {
        print("\nplace your bet (chips: $player_chips, min_bet = $min_bet, max_bet = $max_bet):\n");
        $player_bet = <STDIN>;
        chomp $player_bet;
    }
    
    @player_cards = ($deck[$index++], $deck[$index++]);
    @dealer_cards = ($deck[$index++], $deck[$index++]);

    $player_points = calculate_points(@player_cards);
    $dealer_points = calculate_points($dealer_cards[0]);

    print "\ndealer cards:\n ";
    print $dealer_cards[0]." ($dealer_points)";
    print "\nplayer cards:\n ";
    print join(' ', @player_cards)." ($player_points)";

    @player_states = qw(lose win winbj even);
    $player_state = $player_states[0];
    $double_state = $player_states[0];
    $double_points = 0;
    $double_bet = 0;

    if ($player_points == 21) {
        $player_state = $player_states[2];
    }

    $action = "";
    # player turn
    while ($player_points < 21 and $action ne "pass") {
        @actions = qw(pass hit);
        if (substr($player_cards[0], 0, -1) eq substr($player_cards[1], 0, -1) and $player_chips - $player_bet > 0 and @player_cards == 2) {
            push(@actions, "split");
        }
        print("\nchoose your play (");
        for ($i = 0; $i < @actions; $i++) {
            print(" ".($i+1)." $actions[$i] ");
        }
        print("):\n");
        $action = $actions[<STDIN> - 1];
        print("$action\n");
        if ($action eq "hit") {
            push @player_cards, $deck[$index++];
            $player_points = calculate_points(@player_cards);
            print "\nplayer cards:\n ";
            print join(' ', @player_cards)." ($player_points)";
        } elsif ($action eq "split") {
            @double_cards = pop(@player_cards);
            $player_points = calculate_points(@player_cards);
            $double_points = calculate_points(@double_cards);
            $double_bet = $player_bet;
            print "\nplayer cards:\n ";
            print join(' ', @player_cards)." ($player_points)";
            print "\n ".join(' ', @double_cards)." ($double_points)";
            while ($player_points < 21 and $action ne "pass") {
                @actions = qw(pass hit);
                print("\nchoose your play for the first card (");
                for ($i = 0; $i < @actions; $i++) {
                    print(" ".($i+1)." $actions[$i] ");
                }
                print("):\n");
                $action = $actions[<STDIN> - 1];
                if ($action eq "hit") {
                    push @player_cards, $deck[$index++];
                    $player_points = calculate_points(@player_cards);
                    print "\nplayer cards:\n ";
                    print join(' ', @player_cards)." ($player_points)";
                    print "\n ".join(' ', @double_cards)." ($double_points)";
                }
            }
            if (scalar(@player_cards) == 2 and $player_points == 21) {
                $player_state = $player_states[2];
                print("\nblackjack");
            }
            $action = "";
            while ($double_points < 21 and $action ne "pass") {
                @actions = qw(pass hit);
                print("\nchoose your play for the second card (");
                for ($i = 0; $i < @actions; $i++) {
                    print(" ".($i+1)." $actions[$i] ");
                }
                print("):\n");
                $action = $actions[<STDIN> - 1];
                if ($action eq "hit") {
                    push @double_cards, $deck[$index++];
                    $double_points = calculate_points(@double_cards);
                    print "\nplayer cards:\n ";
                    print join(' ', @player_cards)." ($player_points)";
                    print "\n ".join(' ', @double_cards)." ($double_points)";
                }
            }
            if (scalar(@double_cards) == 2 and $double_points == 21) {
                $double_state = $player_states[2];
                print("\nblackjack!");
            }
            last;
        }
    }

    $dealer_points = calculate_points(@dealer_cards);
    print "\ndealer cards:\n ";
    print join(' ', @dealer_cards)." ($dealer_points)";
    # dealer turn
    $dealer_bj = 0;
    if ($dealer_points == 21) {
        $dealer_bj = 1;
    }
    while ($dealer_points < 17) {
        push @dealer_cards, $deck[$index++];
        $dealer_points = calculate_points(@dealer_cards);
        print "\ndealer cards:\n ";
        print join(' ', @dealer_cards)." ($dealer_points)";
    }

    # calculate win
    if ($player_points > 21) {
        $player_state = $player_states[0]
    } elsif ($dealer_bj and $player_state eq "winbj") {
        $player_state = $player_states[3];
    } elsif ($dealer_points > 21 or ($player_points > $dealer_points and $player_state ne "winbj")) {
        $player_state = $player_states[1];
    } elsif ($player_state ne "winbj" and $player_points == $dealer_points) {
        $player_state = $player_states[3];
    }

    if ($double_bet > 0) {
        if ($double_points > 21) {
            $double_state = $player_states[0];
        } elsif ($dealer_bj and $double_state eq "winbj") {
            $double_state = $player_states[3];
        } elsif ($dealer_points > 21 or ($double_points > $dealer_points and $double_state ne "winbj")) {
            $double_state = $player_states[1];
        } elsif ($double_state ne "winbj" and $double_points == $dealer_points) {
            $double_state = $player_states[3];
        }
    }

    if ($player_state eq "winbj" and not $dealer_bj) {
        $player_chips += int(1.5 * $player_bet);
        print("\nyou win with blackjack! (bet: $player_bet, chips: $player_chips)");
    } elsif ($player_state eq "win") {
        $player_chips += $player_bet;
        print("\nyou win! (bet: $player_bet, chips: $player_chips)");
    } elsif ($player_state eq "even") {
        print("\nbreak even (bet: $player_bet, chips: $player_chips)");
    } else {
        $player_chips -= $player_bet;
        print("\nyou lost the bet (bet: $player_bet, chips: $player_chips)");
    }
    if ($double_bet > 0) {
        if ($double_state eq "winbj" and not $dealer_bj) {
            $player_chips += int(1.5 * $double_bet);
            print("\nyou win with blackjack! (bet: $player_bet, chips: $player_chips)");
        } elsif ($double_state eq "win") {
            $player_chips += $double_bet;
            print("\nyou win! (bet: $player_bet, chips: $player_chips)");
        } elsif ($double_state eq "even") {
            print("\nbreak even (bet: $player_bet, chips: $player_chips)");
        } else {
            $player_chips -= $double_bet;
            print("\nyou lost the bet (bet: $player_bet, chips: $player_chips)");
        }
    }
    print("\n\n");
    sleep(3);
}

