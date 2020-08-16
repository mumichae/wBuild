import sys
import wbuild
import wbuild.scanFiles
import wbuild.autolink

if not '--dag' in sys.argv and not any("snakemake-bash-completion" in s for s in sys.argv):
    depFile = wbuild.scanFiles.writeDependencyFile()

include: depFile

if "htmlIndex" not in config:
    config["htmlIndex"] = "index.html"
if "allDone" not in config:
    config["allDone"] = "Output/all.done"



rule show:
    input: config["allDone"]
    shell: "google-chrome {config[htmlOutputPath]}/{config[htmlIndex]} &"

rule mapScripts:
    input: "scriptMapping.wb"
    output: touch("Output/scriptMapping.done")
    run:
        wbuild.autolink.autolink("scriptMapping.wb")

rule graph:
    output: config["htmlOutputPath"] + "/dep.svg"
    shell: "snakemake --rulegraph | dot -Tsvg -Grankdir=LR > {output}"

rule clean:
    shell: "rm -Rf {config[htmlOutputPath]}* .wBuild/__pycache__"

rule publish:
    input: config["allDone"]
    shell: "rsync -Ort {config[htmlOutputPath]} {config[webDir]}"

rule markdown:
    input: "{file}.md"
    output: expand("{htmlOutputPath}/{{file}}.html", htmlOutputPath = config["htmlOutputPath"])
    shell: "pandoc --from markdown --to html --css {config[wBuildPath]}/html/lib/github.css --toc --self-contained -s -o {output} {input}"

rule restoreModDate:
    shell: "find -type f -exec touch -r {} +"
