package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/kubectl:rolling")
	testhelpers.TestFileExists(t, ctx, image, "/usr/local/bin/kubectl", nil)
}
