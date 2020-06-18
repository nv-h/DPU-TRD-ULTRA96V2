#!/bin/bash

model_name=$1
modelzoo_name=$2
vai_c_caffe \
--prototxt /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy.prototxt \
--caffemodel /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy.caffemodel \
--arch ./custom.json \
--output_dir ./compiled_output/${modelzoo_name} \
--net_name ${model_name} \
--options "{'mode': 'normal'}"
