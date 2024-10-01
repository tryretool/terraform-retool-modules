# This file is provided as an example of custom configuration on top of the AWS
# fluent-bit sidecar image. The default image referenced in locals.tf is built
# and supplied by Retool.

FROM amazon/aws-for-fluent-bit:2.32.3 AS retool-aws-for-fluent-bit

ADD retool-entrypoint.sh /retool-entrypoint.sh
CMD /retool-entrypoint.sh
