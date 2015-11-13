# pdf2ocr

Version 1.2  
November 12, 2015  
Copyright 2007 - 2015 by Jamal Mazrui  
GNU Lesser General Public License (LGPL)  

## Contents
- [Description](#description)
- [Operation](#operation)
- [Development Notes](#development-notes)

## Description

pdf2ocr (pdf2ocr.exe) is a command line utility under Windows that converts one or more PDF files to text using optical character recognition (OCR).  If a PDF includes a text layer, the text can usually be extracted.  Some PDFs, however, are image-only -- the result of a scanning process that takes a picture of each page, creating an image of text but not textual characters, themselves.  Other PDFs include a text layer but their settings make extracting the text difficult.

pdf2ocr uses [Tesseract OCR](https://code.google.com/p/tesseract-ocr/wiki/ReadMe), which is generally considered to be the best, free, open source OCR at this time (sponsored by Google).

## Operation

The simplest, command-line syntax of pdf2ocr is as follows:  
`pdf2ocr FileSpec`

FileSpec can refer to either a single PDF or a wildcard specification for batch converting multiple files, e.g.,  
`pdf2ocr c:\temp\*.pdf`

Each converted file will have the same directory path and root name, differing only in the .txt rather than .pdf extension. The program produces status messages via standard console output.

Up to three more parameters may optionally be passed after the file specification:  DPI, page segmentation mode, and language code.  The default dots per inch (DPI) is 300 for the temporary TIF image that is extracted for each PDF page.  The default page segmentation mode is 3 (explained in Tesseract documentation).  The default language code is "eng" for English.  Text in other languages may be recognized by adding support files from the Tesseract site to the "tessdata" subdirectory of the directory in which pdf2ocr is installed.

The FileSpec parameter should be enclosed in quotes if it contains a space character.  Here is an example using all four possible parameters:  a file specification that includes a space, 150 DPI, page layout mode 1, Spanish:  
`pdf2ocr "c:\temp files\*.pdf" 150 1 spa`

A sample, image-only PDF is included for testing pdf2ocr.  `debate.pdf` is a public, legal agreement on debate rules between U.S. Presidential candidates in 2004.

The pdf2ocr distribution may be installed in any directory, e.g., in `c:\pdf2ocr`.  If that directory is added to the Windows search path, pdf2ocr.exe may be run on the command line within any directory. 

## Development Notes

The pdf2ocr.bas file contains the main source code for the program, built with the [PowerBASIC compiler](http://PowerBASIC.com)

The [QuickPDF library](http://QuickPDFLibrary.com) is used by the program.

Note that these are commercial products needed to successfully compile a new version of the executable. The source code, however, is open and free to share according to the GNU Lesser General Public License (LGPL).

I welcome feedback, which helps pdf2ocr improve over time. When reporting a problem, the more specifics, the better, including steps to reproduce the problem if possible.
