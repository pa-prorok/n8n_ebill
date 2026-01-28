Short Description:

This workflow uses docker and n8n to render ebills in the xbill format. It automatically validates the created files
and renders a pdf file from the e-bill. Credentials for the OpenAI API are required to run this workflow inside n8n

Usage:
1. build the container in the "dinbrief" folder (modify latex files if you want to adjust the bill to your needs)
2. Download n8n and validator containers (docker.n8n.io/n8nio/n8n and easybill/kosit-validator-xrechnung_3.0.2:v0.1.2)
3. Set up n8n volume (see init_script below)
4. Start n8n using docker-compose
5. Import the ebill workflow (json) from the workflow folder

File Description

dinbrief: docker container to render bills using the latex dinbrief template
- ebill.xml contains the template data, change here to update names, accounts and company data
- template/prophet-analytics.tex: template for the letter, modify according to your needs
- template/brfkopf_pa.tex: header of the letter

docker-compose: launch script for docker compose

init_scripts: useful command line inputs to set up n8n

n8n_workflows: json_files for n8n workflows

