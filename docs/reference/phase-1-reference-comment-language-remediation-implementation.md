# Phase 1 reference comment-language remediation implementation — step 168

Step 168 implements only the translations explicitly authorized by the
accepted step-167 remediation design. The implementation is bound to the exact
pre-change SHA-256 recorded by step 167 and refuses any other starting source.

Each authorized syntactic shell-comment payload is translated to English while
preserving its line number, executable-code prefix, comment delimiter, and
line terminator. The helper reconstructs the complete pre-change source by
reversing those translations and requires the reconstructed SHA-256 to match
step 167. This proves that no non-authorized source line changed.

The resulting shell is checked with `bash -n` and the accepted step-166 audit
helper is rerun against the modified source. Zero language defects are required.
The implementation grants no further source-change authorization, no repository
or network refresh, no machine execution, no package or boot action, and no
Phase 2 work. A separate step-169 closure review is required before a strong
safe pause is declared.
