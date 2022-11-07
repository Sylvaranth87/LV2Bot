*** Settings ***
Documentation       Order robots from RobotSpareBin.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Variables ***
${folder_pdf}       ${CURDIR}${/}pdf_files
${folder_img}       ${CURDIR}${/}img_files
${folder_output}    ${CURDIR}{/}output


*** Tasks ***
Order robots from RobotSpareBin
    Cleanup previous files
    ${url}=    Collect url from user
    ${orders}=    Get orders    ${url}
    Open the order website
    FOR    ${row}    IN    @{orders}
        Close annoying popup
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Check the order
        ${screenshot}=    Take a screenshot of the robot
        ${pdf}=    Store the receipt as a PDF file
        Embed the robot screenshot
        Next order
    END
    Create ZIP file of the receipts


*** Keywords ***
Cleanup previous files
    Create Directory    ${folder_output}
    Create Directory    ${folder_pdf}
    Create Directory    ${folder_img}

    Empty Directory    ${folder_pdf}
    Empty Directory    ${folder_img}
    Empty Directory    ${folder_output}

Collect url from user
    Add text input    url    label=Insert CSV url    placeholder=url here
    ${response}=    Run dialog
    RETURN    ${response.url}
    Log    ${response.url}

Get orders
    [Arguments]    ${url}
    Download    ${url}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Open the order website
    ${secret}=    Get Secret    webvault
    Open Available Browser    ${secret}[robotweb]

Close annoying popup
    Wait And Click Button    Xpath=//html/body/div/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${table}
    Wait Until Element Is Enabled    id:head
    Select From List By Value    id:head    ${table}[Head]
    Select Radio Button    body    ${table}[Body]
    Input Text    Xpath=//html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${table}[Legs]
    Input Text    address    ${table}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button    id:order

Check the order
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${alert}'=='True'    Click Button    id:order
        IF    '${alert}'=='False'            BREAK
    END

Take a screenshot of the robot
    Wait Until Element Is Visible    id:robot-preview-image
    ${order_id}=    Get Text    Xpath=//html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_file}    ${folder_img}${/}${order_id}.png
    Screenshot    id:robot-preview-image    ${img_file}
    RETURN    ${order_id}    ${img_file}

Store the receipt as a PDF file
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${order_id}=    Get Text    Xpath=//html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${pdf_file}    ${folder_pdf}${/}${order_id}.pdf
    Html To Pdf    ${receipt_html}    output_path=${pdf_file}
    RETURN    ${pdf_file}

Embed the robot screenshot
    ${order_id}=    Get Text    Xpath=//html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_file}    ${folder_img}${/}${order_id}.png
    Set Local Variable    ${pdf_file}    ${folder_pdf}${/}${order_id}.pdf
    ${file}=    Create List    ${img_file}:align=center
    Open Pdf    ${pdf_file}
    Add Files To Pdf    ${file}    ${pdf_file}    append=True

Next order
    Click Button    //*[@id="order-another"]

Create ZIP file of the receipts
    Archive Folder With Zip    ${folder_pdf}    receipts.zip    recursive=True
