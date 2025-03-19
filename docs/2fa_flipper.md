# Two-Factor Authentication (2FA) Flipper in Staging

This document describes the implementation of a Flipper feature for controlling Two-Factor Authentication (2FA) in the Staging environment.

## Overview

To support load testing for Migration testing, a Flipper feature for 2FA has been implemented in the Staging environment. This allows developers to temporarily disable 2FA when needed for load testing purposes.

By default, 2FA is enabled in Staging (as it is in all environments), but it can now be toggled on/off using the Flipper feature via Rails console.

## Implementation Details

The implementation includes:

1. A Flipper feature named `two_factor_authentication` that controls 2FA in the Staging environment
2. A modification to `config/application.rb` to use this Flipper feature in Staging
3. Tests to verify the functionality

## How to Use

### Managing 2FA in Staging

You can manage 2FA in the Staging environment by using the Rails console:

```bash
# SSH into the staging server
# Then open the Rails console
bin/rails console

# Check the current status
Flipper.enabled?(:two_factor_authentication)
```

### Disabling 2FA for Load Testing

To disable 2FA in Staging (for load testing purposes only):

```ruby
# In the Rails console
Flipper.disable(:two_factor_authentication)

# Verify the feature is disabled
Flipper.enabled?(:two_factor_authentication)  # Should return false
```

### Re-enabling 2FA

After load testing is complete, make sure to re-enable 2FA:

```ruby
# In the Rails console
Flipper.enable(:two_factor_authentication)

# Verify the feature is enabled
Flipper.enabled?(:two_factor_authentication)  # Should return true
```

## Important Notes

1. 2FA should only be disabled temporarily for load testing purposes
2. Always re-enable 2FA after testing is complete
3. This Flipper feature only affects the Staging environment
4. In all other environments, 2FA is controlled by the `TWO_FACTOR_AUTHENTICATION_ENABLED` environment variable

## Related Files

- `config/application.rb` - Contains the logic to use Flipper for 2FA in Staging
- `db/migrate/20250314164520_add_two_factor_authentication_flipper.rb` - Creates and enables the Flipper feature
- `spec/features/two_factor_authentication_flipper_spec.rb` - Tests for the feature
