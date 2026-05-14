geolint is a small utility to scan files or directories
looking for images that have GPS metadata in their EXIF info,
used to verify that you've removed any geolocation data prior to making images public.
You might use this on a website or personal notes directory.


## AI use

This is a vibecoded tool that I see as an improvement for myself
because it replaces having nothing at all.
Claude Code wrote almost this entire tool,
and I have not read the code in detail,
though I have tested it myself
and there are extensive automated tests
(but most of the latter were also written by Claude).


## Security

Owing to the fact that this is a vibecoded one-evening project,
if you are in a high-security environment
where it is critical that geolocation data not be exposed,
**please do your own verification** that it works for your use case before trusting this tool.
There is NO WARRANTY on this software detecting all possible geolocation
or general infosec risks related to an image.

If you notice something that the script missed that it should have caught,
please get in touch at `contact@sorenbjornstad.com`.
