package MT::Plugin::Editing::OMV::TabEnabler;
# $Id$

use strict;
#use MT 5;

use vars qw( $VENDOR $MYNAME $VERSION );
($VENDOR, $MYNAME) = (split /::/, __PACKAGE__)[-2, -1];
(my $revision = '$Rev$') =~ s/\D//g;
$VERSION = '0.10'. ($revision ? "_$revision" : '');

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new ({
    id => $MYNAME,
    key => $MYNAME,
    name => $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
    plugin_link => 'http://www.magicvox.net/archive/2012/10221630/', # Blog
    doc_link => 'http://lab.magicvox.net/trac/mt-plugins/wiki/TabEnabler', # tracWiki
    description => <<'HTMLHEREDOC',
<__trans phrase="Enable inserting a Tab code with Tab key in Entry, Page and Template editing screen.">
HTMLHEREDOC
    l10n_class => $MYNAME. '::L10N',
    registry => {
        callbacks => {
            'MT::App::CMS::template_source.edit_entry' => \&_hdlr_template_source_edit_entry,
            'MT::App::CMS::template_source.edit_template' => \&_hdlr_template_source_edit_template,
        },
    },
});
MT->add_plugin ($plugin);

sub instance { $plugin; }



### JavaScript for handling that tab key pressed.
sub _js_tab_hook {
    <<'JSHEREDOC';
    if (ev.keyCode != 9 || ev.type != 'keydown')
        return true;

    var insert = ev.shiftKey
        ? "    "
        : "\t";

    var ta = ev.target;
    if (document.selection) {
        ta.focus();
        document.selection.createRange().text = insert;
    }
    else {
        var ss = ta.selectionStart,
            se = ta.selectionEnd,
            st = ta.scrollTop,
            tv = ta.value;
        ta.value = tv.substring(0, ss).concat(insert, tv.substring(se));
        ta.selectionStart = ta.selectionEnd = ss + insert.length;
        ta.scrollTop = st;
    }

    ev.stopPropagation && ev.stopPropagation();
    ev.preventDefault && ev.preventDefault();
    return false;
JSHEREDOC
}



### Modify template for Entry/Page editing screen
sub _hdlr_template_source_edit_entry {
    my ($cb, $app, $tmpl) = @_;

    # Adding KeyEvent for normal textarea
    my $old = quotemeta (<<'MTMLHEREDOC');
<mt:include name="include/footer.tmpl" id="footer_include">
MTMLHEREDOC
    my $new = <<"MTMLHEREDOC";
<mt:setvarblock name="jq_js_include" append="1">
// $MYNAME (@{[ do { &instance->plugin_link; } ]})
jQuery('#editor-content-textarea').keydown (function (ev) {
@{[ do { _js_tab_hook(); } ]}
});
</mt:setvarblock>
MTMLHEREDOC
    $$tmpl =~ s/($old)/$new$1/;
}

### Modify template for Template editing screen
sub _hdlr_template_source_edit_template {
    my ($cb, $app, $tmpl) = @_;

    # Adding KeyEvent for CodeMirror
    my $old = quotemeta (<<'MTMLHEREDOC');
lineNumbers: true,
MTMLHEREDOC
    my $new = <<"MTMLHEREDOC";
// $MYNAME (@{[ do { &instance->plugin_link; } ]})
onKeyEvent: function (self, ev) {
@{[ do { _js_tab_hook(); } ]}
},
MTMLHEREDOC
    $$tmpl =~ s/($old)/$new$1/;

    # Adding KeyEvent for normal textarea
    $old = quotemeta (<<'MTMLHEREDOC');
<mt:include name="include/footer.tmpl">
MTMLHEREDOC
    $new = <<"MTMLHEREDOC";
<mt:setvarblock name="jq_js_include" append="1">
// $MYNAME (@{[ do { &instance->plugin_link; } ]})
jQuery('#text').keydown (function (ev) {
@{[ do { _js_tab_hook(); } ]}
});
</mt:setvarblock>
MTMLHEREDOC
    $$tmpl =~ s/($old)/$new$1/;
}

1;