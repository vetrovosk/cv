[![build](https://github.com/apprme/cv/actions/workflows/build.yml/badge.svg)](https://github.com/apprme/cv/actions/workflows/build.yml)

The CV is automatically built and deployed to AWS using
[GitHub Actions](https://github.com/apprme/cv/blob/main/.github/workflows/build.yml).
All the necessary AWS infrastructure used to serve the CV, including
ACM SSL certificate, S3 bucket and CloudFront distribution, is created
using [Terraform](https://github.com/apprme/cv/tree/main/terraform).
 
The latest version of the CV is available at [cv.appr.me](https://cv.appr.me/).