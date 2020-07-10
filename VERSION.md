## Version 0.2.0 (2020-07-10)

Minor:

  * Removed `@navigate-timeout` configuration setting.

    I have implemented proper edge detection (no more timeouts!) in the Vim
    portion of this plugin by reporting navigable directions in Vim's title.

Other:

  * Moved tmux navigation logic out of string literal.

  * Added documentation comments; improved formatting.

## Version 0.1.1 (2020-05-06)

Patch:

  * README: Vim integration required for local control.

    Since we rely on pane title changes to check whether Vim navigation was
    successful, the included Vim plugin is also necessary for local control
    (it's not only for remote control, where we connect to Vim through SSH).

  * GH-1: don't send BSpace upon Vim misidentification.

    For example, Vim 7.2 sets the pane title to "Thanks for flying Vim" and
    doesn't bother to clean up after itself upon termination.  As a result,
    the old navigation logic would still see "Thanks for flying Vim" as the
    title and think that Vim was still running: therefore misidentification.

## Version 0.1.0 (2020-04-25)

Minor:

  * Release [blog snippet] as a proper [TPM] plugin: `tmux-navigate`.

    Thanks to @bradleyharden for contributing a working example of TPM
    plugin conversion and giving me the opportunity to host this repo.

[TPM]: https://github.com/tmux-plugins/tpm
[blog snippet]: https://sunaku.github.io/tmux-select-pane.html
