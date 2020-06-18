#!/bin/bash

model_name=$1
modelzoo_name=$2
vai_c_tensorflow \
--frozen_pb /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy_model.pb \
--arch ./custom.json \
--output_dir ./compiled_output/${modelzoo_name} \
--net_name ${model_name}
