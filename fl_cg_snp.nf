/*
Note:
Before running the script, please set the parameters in the config file params.yaml
*/

//Step1:input data files
nextflow.enable.dsl=2

myDir = file("$params.input")


include { flcgsnp } from './modules/flcgsnp.nf'

workflow {
    flcgsnp(myDir) | view
}
