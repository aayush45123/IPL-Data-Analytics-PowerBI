-- QUESTION 1
-- How has the scoring pattern of IPL changed across seasons?
-- This analysis compares the average innings score and run rate
-- for every season. It helps us understand whether batting has
-- become more aggressive over the years.

WITH innings_data AS (
    SELECT
        season,
        match_id,
        innings,
        SUM(runs_total) AS innings_runs,
        COUNT(*) FILTER (
            WHERE valid_ball = 1
        ) AS legal_balls
    FROM ipl_data
    GROUP BY season, match_id, innings
)

SELECT
    season,
    COUNT(DISTINCT match_id) AS matches,
    ROUND(AVG(innings_runs), 2) AS average_innings_score,
    ROUND(
        SUM(innings_runs) * 6.0 /
        NULLIF(SUM(legal_balls), 0),
        2
    ) AS run_rate
FROM innings_data
GROUP BY season
ORDER BY season;


-- QUESTION 2
-- Which teams are the most consistent at scoring runs?
-- Instead of looking only at total runs, this analysis looks at
-- average score, highest score, lowest score and score variation.
-- A lower variation means the team scores more consistently.

WITH team_innings AS (
    SELECT
        batting_team,
        match_id,
        innings,
        SUM(runs_total) AS total_runs
    FROM ipl_data
    GROUP BY batting_team, match_id, innings
)

SELECT
    batting_team,
    COUNT(*) AS innings_played,
    ROUND(AVG(total_runs), 2) AS average_score,
    ROUND(STDDEV(total_runs), 2) AS score_variation,
    MIN(total_runs) AS lowest_score,
    MAX(total_runs) AS highest_score
FROM team_innings
GROUP BY batting_team
HAVING COUNT(*) >= 20
ORDER BY average_score DESC;


-- QUESTION 3
-- Which teams are the most successful when chasing a target?
-- This compares the first innings score with the second innings
-- score and calculates the percentage of successful chases.
-- It helps identify teams that perform well under chasing pressure.

WITH innings_scores AS (
    SELECT
        match_id,
        innings,
        batting_team,
        SUM(runs_total) AS runs
    FROM ipl_data
    GROUP BY match_id, innings, batting_team
),

match_scores AS (
    SELECT
        match_id,

        MAX(
            CASE
                WHEN innings = 1 THEN runs
            END
        ) AS first_innings_score,

        MAX(
            CASE
                WHEN innings = 2 THEN batting_team
            END
        ) AS chasing_team,

        MAX(
            CASE
                WHEN innings = 2 THEN runs
            END
        ) AS chasing_score

    FROM innings_scores
    GROUP BY match_id
)

SELECT
    chasing_team,
    COUNT(*) AS chases,

    COUNT(*) FILTER (
        WHERE chasing_score > first_innings_score
    ) AS successful_chases,

    ROUND(
        COUNT(*) FILTER (
            WHERE chasing_score > first_innings_score
        ) * 100.0 / COUNT(*),
        2
    ) AS chase_success_rate

FROM match_scores

WHERE chasing_team IS NOT NULL

GROUP BY chasing_team

HAVING COUNT(*) >= 10

ORDER BY chase_success_rate DESC;


-- QUESTION 4
-- Does winning the toss actually increase the chance of winning
-- the match?
-- This analysis compares the toss winner with the actual match
-- winner. It tells us whether the toss provides a meaningful
-- historical advantage.

WITH match_results AS (
    SELECT DISTINCT
        match_id,
        toss_winner,
        match_won_by
    FROM ipl_data

    WHERE toss_winner IS NOT NULL
      AND match_won_by IS NOT NULL
)

SELECT
    COUNT(*) AS total_matches,

    COUNT(*) FILTER (
        WHERE toss_winner = match_won_by
    ) AS toss_winner_wins,

    ROUND(
        COUNT(*) FILTER (
            WHERE toss_winner = match_won_by
        ) * 100.0 / COUNT(*),
        2
    ) AS toss_win_percentage

FROM match_results;


-- QUESTION 5
-- Which teams score most aggressively during the Powerplay?
-- The first six overs can strongly influence an innings.
-- This query calculates the average Powerplay score and run rate
-- for each team, allowing us to compare their early-innings
-- attacking ability.

WITH powerplay AS (
    SELECT
        batting_team,
        match_id,

        SUM(runs_total) AS runs,

        COUNT(*) FILTER (
            WHERE valid_ball = 1
        ) AS legal_balls

    FROM ipl_data

    WHERE over BETWEEN 0 AND 5

    GROUP BY batting_team, match_id
)

SELECT
    batting_team,

    COUNT(*) AS innings,

    ROUND(
        AVG(runs),
        2
    ) AS average_powerplay_runs,

    ROUND(
        SUM(runs) * 6.0 /
        NULLIF(SUM(legal_balls), 0),
        2
    ) AS powerplay_run_rate

FROM powerplay

GROUP BY batting_team

HAVING COUNT(*) >= 20

ORDER BY powerplay_run_rate DESC;


-- QUESTION 6
-- Which teams accelerate the most from the Powerplay to the
-- Death Overs?
-- This compares the run rate during overs 0-5 with the run rate
-- during overs 16-19. A high acceleration value indicates that
-- a team becomes significantly more aggressive at the end
-- of its innings.

WITH phase_scores AS (
    SELECT
        batting_team,
        match_id,

        SUM(
            CASE
                WHEN over BETWEEN 0 AND 5
                THEN runs_total
                ELSE 0
            END
        ) AS powerplay_runs,

        SUM(
            CASE
                WHEN over BETWEEN 16 AND 19
                THEN runs_total
                ELSE 0
            END
        ) AS death_runs,

        COUNT(*) FILTER (
            WHERE over BETWEEN 0 AND 5
              AND valid_ball = 1
        ) AS powerplay_balls,

        COUNT(*) FILTER (
            WHERE over BETWEEN 16 AND 19
              AND valid_ball = 1
        ) AS death_balls

    FROM ipl_data

    GROUP BY batting_team, match_id
)

SELECT
    batting_team,

    ROUND(
        SUM(powerplay_runs) * 6.0 /
        NULLIF(SUM(powerplay_balls), 0),
        2
    ) AS powerplay_run_rate,

    ROUND(
        SUM(death_runs) * 6.0 /
        NULLIF(SUM(death_balls), 0),
        2
    ) AS death_run_rate,

    ROUND(
        (
            SUM(death_runs) * 6.0 /
            NULLIF(SUM(death_balls), 0)
        )
        -
        (
            SUM(powerplay_runs) * 6.0 /
            NULLIF(SUM(powerplay_balls), 0)
        ),
        2
    ) AS acceleration

FROM phase_scores

GROUP BY batting_team

ORDER BY acceleration DESC;


-- QUESTION 7
-- Which batsmen have the best strike rate while maintaining
-- a meaningful sample size?
-- Ranking only by strike rate can be misleading because a player
-- with very few balls may appear at the top. Here we consider
-- only batsmen who have faced at least 500 legal balls.

WITH batting AS (
    SELECT
        batter,

        SUM(runs_batter) AS runs,

        COUNT(*) FILTER (
            WHERE valid_ball = 1
        ) AS balls

    FROM ipl_data

    GROUP BY batter
)

SELECT
    batter,
    runs,
    balls,

    ROUND(
        runs * 100.0 /
        NULLIF(balls, 0),
        2
    ) AS strike_rate

FROM batting

WHERE balls >= 500

ORDER BY strike_rate DESC

LIMIT 20;


-- QUESTION 8
-- Which bowlers create the most dot-ball pressure?
-- Wickets are not the only measure of bowling quality.
-- Dot balls create pressure and can force batsmen to take
-- risky shots. This query compares dot-ball percentage among
-- bowlers with a reasonable number of deliveries.

SELECT
    bowler,

    COUNT(*) FILTER (
        WHERE valid_ball = 1
    ) AS legal_balls,

    COUNT(*) FILTER (
        WHERE valid_ball = 1
          AND runs_total = 0
    ) AS dot_balls,

    ROUND(
        COUNT(*) FILTER (
            WHERE valid_ball = 1
              AND runs_total = 0
        ) * 100.0 /

        NULLIF(
            COUNT(*) FILTER (
                WHERE valid_ball = 1
            ),
            0
        ),

        2
    ) AS dot_ball_percentage

FROM ipl_data

GROUP BY bowler

HAVING COUNT(*) FILTER (
    WHERE valid_ball = 1
) >= 500

ORDER BY dot_ball_percentage DESC;


-- QUESTION 9
-- Which venues are the most batting-friendly?
-- Different stadiums can produce very different scoring patterns.
-- This query calculates average match runs at each venue so that
-- we can identify venues where high-scoring matches are more common.

WITH venue_matches AS (
    SELECT
        venue,
        match_id,
        SUM(runs_total) AS total_runs

    FROM ipl_data

    GROUP BY venue, match_id
)

SELECT
    venue,

    COUNT(*) AS matches,

    ROUND(
        AVG(total_runs),
        2
    ) AS average_match_runs,

    ROUND(
        STDDEV(total_runs),
        2
    ) AS score_variation

FROM venue_matches

GROUP BY venue

HAVING COUNT(*) >= 10

ORDER BY average_match_runs DESC;


-- QUESTION 10
-- Which teams have the strongest overall batting profile?
-- This combines multiple batting indicators instead of ranking
-- teams using only total runs. It compares runs per match,
-- run rate, boundaries and dot-ball percentage to understand
-- how teams build their innings.

WITH team_stats AS (
    SELECT
        batting_team,

        SUM(runs_total) AS total_runs,

        COUNT(DISTINCT match_id) AS matches,

        COUNT(*) FILTER (
            WHERE runs_batter = 4
        ) AS fours,

        COUNT(*) FILTER (
            WHERE runs_batter = 6
        ) AS sixes,

        COUNT(*) FILTER (
            WHERE valid_ball = 1
        ) AS legal_balls,

        COUNT(*) FILTER (
            WHERE runs_total = 0
              AND valid_ball = 1
        ) AS dot_balls

    FROM ipl_data

    GROUP BY batting_team
)

SELECT
    batting_team,

    matches,

    total_runs,

    ROUND(
        total_runs * 1.0 /
        NULLIF(matches, 0),
        2
    ) AS runs_per_match,

    fours,

    sixes,

    ROUND(
        total_runs * 100.0 /
        NULLIF(legal_balls, 0),
        2
    ) AS run_rate,

    ROUND(
        dot_balls * 100.0 /
        NULLIF(legal_balls, 0),
        2
    ) AS dot_ball_percentage

FROM team_stats

ORDER BY run_rate DESC;