geolint is a small utility to scan files or directories
looking for images that have GPS metadata in their EXIF info,
used to verify that you've removed any geolocation data prior to making images public.
You might use this on a website or personal notes directory.


## Security

Claude Code wrote almost the entire tool.
While there are fairly extensive tests, most of those were also written by Claude.
I am happy using this because, for me, it replaces having nothing at all,
while being easy enough to create it was worth doing the work.
But if you are in a high-security environment
where it is critical that geolocation data not be exposed,
**please do your own verification** and do not just trust this tool.
There is NO WARRANTY on this software detecting all possible geolocation
or general infosec risks related to an image.

If you notice something that the script missed that it should have caught,
please get in touch at `contact@sorenbjornstad.com`.
