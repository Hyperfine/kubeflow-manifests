package test

import (
	"context"
	"fmt"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	pgx "github.com/jackc/pgx/v4"
	"github.com/stretchr/testify/assert"
)

type RDSInfo struct {
	Username   string
	Password   string
	DBName     string
	DBEndpoint string
	DBPort     string
}

// smokeTestPostgres smoke tests a postgres database by running select 1+1 and verifying it returns 2.
func smokeTestPostgres(t *testing.T, serverInfo RDSInfo) {
	result := retry.DoWithRetry(
		t,
		"select 1+1 in postgres",
		// Try 10 times, 30 seconds apart. The most common failure here is an out of memory issue, so when we run into
		// it, we want to space out the calls so that they don't overlap with other terraform calls happening.
		10,
		30*time.Second,
		func() (string, error) {
			query := "SELECT 1+1;"
			var result int
			scanErr := makeQuery(serverInfo, query, &result)
			if scanErr != nil {
				return "", scanErr
			}
			return strconv.Itoa(result), nil
		},
	)
	assert.Equal(t, "2", result)
}

// createPostgresDB will create the requested DB in the provided postgres server.
func createPostgresDB(t *testing.T, serverInfo RDSInfo, dbname string) {
	result := retry.DoWithRetry(
		t,
		"create DB in postgres",
		// Try 10 times, 30 seconds apart. The most common failure here is an out of memory issue, so when we run into
		// it, we want to space out the calls so that they don't overlap with other terraform calls happening.
		10,
		30*time.Second,
		func() (string, error) {
			query := fmt.Sprintf("CREATE DATABASE %s;", dbname)
			var result string
			scanErr := makeQuery(serverInfo, query, &result)
			if scanErr == pgx.ErrNoRows {
				return "OK", nil
			}
			return "", scanErr
		},
	)
	assert.Equal(t, "OK", result)
}

func makeQuery(serverInfo RDSInfo, query string, result interface{}) error {
	dbConnString := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
		serverInfo.Username,
		serverInfo.Password,
		serverInfo.DBEndpoint,
		serverInfo.DBPort,
		serverInfo.DBName,
	)
	db, connErr := pgx.Connect(context.Background(), dbConnString)
	if connErr != nil {
		return connErr
	}
	defer db.Close(context.Background())

	row := db.QueryRow(context.Background(), query)
	return row.Scan(result)
}
