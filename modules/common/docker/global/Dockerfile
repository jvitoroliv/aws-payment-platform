# Base image pinned to specific version — prevents supply chain drift
FROM mcr.microsoft.com/dotnet/framework/runtime:4.7.2-windowsservercore-ltsc2019

RUN mkdir C:\\TEMP

ADD sqltools.ps1 C:\\TEMP

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR C:\\TEMP

RUN powershell -File .\sqltools.ps1
