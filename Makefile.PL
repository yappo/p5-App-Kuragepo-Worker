use inc::Module::Install;
name 'App-Kuragepo-Worker';
all_from 'lib/App/Kuragepo/Worker.pm';
readme_from 'lib/App/Kuragepo/Worker.pm';
readme_markdown_from 'lib/App/Kuragepo/Worker.pm';
githubmeta;

requires 'parent';
requires 'JSON';
requires 'Net::MPRPC::Client';
requires 'Gearman::Client';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
