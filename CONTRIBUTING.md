# Using the issue tracker

The issue tracker is the preferred channel for [bug reports](#bugs) and [features requests](#features). Please label each issue accordingly. Please do no use issues as Q&A sections.

## Bug reports

A bug is a _demonstrable problem_ that is caused by the code in the repository.
Good bug reports are extremely helpful - thank you!

Before submitting a bug report:

1. **Check if the issue has been fixed**; try to reproduce it using the latest `master` _or_ development branch in the repository.

2. **Check the requirements of the project**; do you have issues in package loading? have you tried to restart R session?

3. **Check if the bug is already submitted in the issue tracker**; use github search engine, it's quite good.

If you can't solve the bug on your own, then:

1. **Try to isolate the problem** &mdash; create a [reduced test case](http://css-tricks.com/reduced-test-cases/) and a live example. 

2. **Check bug conditions** &mdash; does it occur always? if not, what is different from the case when th bug occurs from the well working state? Can you yourself pinpoint the exact problem?

3. **Report the problem** &mdash; reported issue shoudl attend to the following areas:
  a) Describe the problem - in case of the error/warning copy the entire message
  b) State what version of the repo - HEAD commit - are you using
  b) what version of R and imported libraries are you using
  c) If possible, provide script and data to reproduce the issue

4. **Suggestions** &mdash; if you can pinpoint the problem to a certain line and don't want to fix it yourself and create a pull request, state your opinion/thought or what might be wrong


A good bug report shouldn't leave others needing to chase you up for more information. Please try to be as detailed as possible in your report.

Example:

> function get_data doesn't return anything
>
> I am using the most updated master branch. After reading all the data iwith the get_data function, the assigned object is empty. I loaded all libraries without warnings or errors. The functions doesn't produce an error, runs for approx 10 seconds and then returns NULL.
>
> 1. Loaded libraries and all scripts.
> 2. path = "/data/1/"
> 3. get_data(path)
>
> Data can be found at "https://onedrive.live.com/datapath"


<a name="features"></a>
## Feature requests

Please be as specific in the feature requests as possible. Label features as such. Create one issue per feature. Follow up on the feature. SOmetimes it will be explained without any changes to the code.

Example
> I would like a function to extract number of evets in a specific timewindow

or

> I would like to be able to plot development of skills over multiple sessions
