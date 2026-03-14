package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/rsync:rolling")
	testhelpers.TestFileExists(t, ctx, image, "/usr/bin/rsync", nil)
}
