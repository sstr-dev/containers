package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/k8s-crd-extractor:rolling")

	for _, f := range []string{
		"/app/crd-extractor.sh",
		"/app/openapi2jsonschema.py",
		"/usr/bin/kubectl",
	} {
		t.Run(f, func(t *testing.T) {
			testhelpers.TestFileExists(t, ctx, image, f, nil)
		})
	}
}
