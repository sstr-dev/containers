package main

import (
	"context"
	"testing"

	"github.com/sstr-dev/containers/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/unifi-api-browser:rolling")
	testhelpers.TestHTTPEndpoint(t, ctx, image, testhelpers.HTTPTestConfig{Port: "8000"}, nil)
}

func TestConfigRenderingFromEnv(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/unifi-api-browser:rolling")

	config := &testhelpers.ContainerConfig{
		Env: map[string]string{
			"CONTROLLERS_0_TYPE":       "classic",
			"CONTROLLERS_0_NAME":       "Home",
			"CONTROLLERS_0_URL":        "https://192.168.1.1:443",
			"CONTROLLERS_0_USER":       "alice",
			"CONTROLLERS_0_PASSWORD":   "secret",
			"CONTROLLERS_0_VERIFY_SSL": "false",
			"CONTROLLERS_1_TYPE":       "official",
			"CONTROLLERS_1_NAME":       "Office",
			"CONTROLLERS_1_URL":        "https://network.example.com",
			"CONTROLLERS_1_TOKEN":      "token-123",
			"CONTROLLERS_1_VERIFY_SSL": "true",
			"THEME":                    "yeti",
			"NAVBAR_CLASS":             "light",
			"NAVBAR_BG_CLASS":          "primary",
			"DEBUG":                    "true",
		},
	}

	testhelpers.TestCommandSucceeds(
		t,
		ctx,
		image,
		config,
		"bash",
		"-lc",
		"(/entrypoint.sh >/tmp/unifi-api-browser.log 2>&1 &) && for i in $(seq 1 20); do test -f /app/config/config.php && break; sleep 0.2; done && grep -F \"'username' => 'alice'\" /app/config/config.php && grep -F \"'api_key' => 'token-123'\" /app/config/config.php && grep -F \"'type' => 'official'\" /app/config/config.php && grep -F \"'verify_ssl' => false\" /app/config/config.php && grep -F \"\\$theme = 'yeti';\" /app/config/config.php && grep -F \"\\$navbar_class = 'light';\" /app/config/config.php && grep -F \"\\$navbar_bg_class = 'primary';\" /app/config/config.php && grep -F \"\\$debug = true;\" /app/config/config.php",
	)
}

func TestUsersRenderingFromEnv(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/unifi-api-browser:rolling")

	config := &testhelpers.ContainerConfig{
		Env: map[string]string{
			"CONTROLLERS_0_TYPE":     "classic",
			"CONTROLLERS_0_NAME":     "Home",
			"CONTROLLERS_0_URL":      "https://192.168.1.1:443",
			"CONTROLLERS_0_USER":     "alice",
			"CONTROLLERS_0_PASSWORD": "secret",
			"USERS_0_USER_NAME":      "admin",
			"USERS_0_PASSWORD":       "admin",
			"USERS_1_USER_NAME":      "readonly",
			"USERS_1_PASSWORD_HASH":  "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043",
		},
	}

	testhelpers.TestCommandSucceeds(
		t,
		ctx,
		image,
		config,
		"bash",
		"-lc",
		"(/entrypoint.sh >/tmp/unifi-api-browser.log 2>&1 &) && for i in $(seq 1 20); do test -f /app/config/users.php && break; sleep 0.2; done && grep -F \"'user_name' => 'admin'\" /app/config/users.php && grep -F \"'password' => 'c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec'\" /app/config/users.php && grep -F \"'user_name' => 'readonly'\" /app/config/users.php && grep -F \"'password' => '9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043'\" /app/config/users.php",
	)
}

func TestUsersRenderingSkippedWithoutEnv(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/sstr-dev/unifi-api-browser:rolling")

	config := &testhelpers.ContainerConfig{
		Env: map[string]string{
			"CONTROLLERS_0_TYPE":     "classic",
			"CONTROLLERS_0_NAME":     "Home",
			"CONTROLLERS_0_URL":      "https://192.168.1.1:443",
			"CONTROLLERS_0_USER":     "alice",
			"CONTROLLERS_0_PASSWORD": "secret",
		},
	}

	testhelpers.TestCommandSucceeds(
		t,
		ctx,
		image,
		config,
		"bash",
		"-lc",
		"(/entrypoint.sh >/tmp/unifi-api-browser.log 2>&1 &) && for i in $(seq 1 20); do test -f /app/config/config.php && break; sleep 0.2; done && test ! -f /app/config/users.php",
	)
}
