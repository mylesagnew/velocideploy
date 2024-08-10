#!/bin/bash

sed -i '' '/^ssh -i/d' velociraptor.sh

cd "${0%/*}"

terraform destroy
