package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/manyfold:rolling")

	t.Run("HTTP endpoint test", func(t *testing.T) {
		testhelpers.TestHTTPEndpoint(t, ctx, image,
			testhelpers.HTTPTestConfig{
				Port: "3214",
				Path: "/health",
			},
			&testhelpers.ContainerConfig{
				Env: map[string]string{
					"SECRET_KEY_BASE":   "placeholder",
					"DATABASE_URL":      "sqlite3:/data/manyfold.sqlite3",
					"RUN_BUILTIN_REDIS": "true",
				},
			},
		)
	})
}
