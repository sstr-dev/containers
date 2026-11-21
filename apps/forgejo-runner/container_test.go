package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/forgejo-runner:rolling")

	for _, f := range []string{
		"/usr/bin/clang",
		"/usr/bin/llvm-config",
		"/usr/bin/rsync",
		"/usr/local/bin/cosign",
		"/usr/local/bin/fjo",
		"/usr/local/bin/flate",
		"/usr/local/bin/flux",
		"/usr/local/bin/gh",
		"/usr/local/bin/helm",
		"/usr/local/bin/kustomize",
	} {
		t.Run(f, func(t *testing.T) {
			testhelpers.TestFileExists(t, ctx, image, f, nil)
		})
	}
}
