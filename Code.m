clear;
clc;
[sig1,fs1] = audioread("E:\Documents\Third Year First Semister\Communications\Project\Short_BBCArabic2.wav");
%single channel stream of sig1
sig2 = sig1(:,1) + sig1 (:,2);
[sig3,fs2] = audioread("E:\Documents\Third Year First Semister\Communications\Project\Short_FM9090.wav");
%single channel stream of sig2
sig4 = sig3(:,1) + sig3 (:,2);
%padding the short signal with zeros, so the two signals have the same length
sig5 = [sig4;zeros(43008,1)];
L=length(sig5);
k=-L/2:L/2-1;
Y1=fft(sig2,L);
Y2=fft(sig5,L);
subplot(4,2,1);
plot(k*fs1/L,fftshift(abs(Y1))); %bw = 10^4 HZ
title('fft of msg1')
subplot(4,2,2);
plot(k*fs2/L,fftshift(abs(Y2))); %bw = 10^4 HZ
title('fft of msg2')
%....The transmitter....%
message1= interp(sig2,10); %increasing the number of samples of the modulating signals
message2= interp(sig5,10); %increasing the number of samples of the modulating signals
fs_new=10*fs1; %fs after using interp function
L_new=10*L; %no of samples after using interp function
f1=100*10^3; %the carrier freq to modualte the first signal
f2=150*10^3; %the carrier freq to modualte the second signal
BW = 10^4; %bandwidth of each siganl
Ts=1/(fs_new);
n1=0:L_new-1;
c1=cos(2*pi*f1*n1'.*Ts);
c2=cos(2*pi*f2*n1'.*Ts);
modulated_message1= 2*message1.*c1;
modulated_message2= message2.*c2;
final_modulated= modulated_message1 + modulated_message2;
Y3=fft(final_modulated,L_new);
k1=-L_new/2:L_new/2-1;
subplot(4,2,3);
plot(k1*fs_new/L_new,fftshift(abs(Y3)));
title('The spectrum of the output of the transmitter');
%.....The RF stage.....%
Fif=25*10^3;
%...f_desired determines which message we want at the Receiver...%
%when choosing 1 then f_desired=f1 and you will Receive the first Message at receiver..%
%when choosing 2 then f_desired=f2 and you will Receive the second message at receiver..%
while 1
prompt= "enter the channel number (1 or 2): ";
ch = input(prompt);
if (ch==1)
f_desired=f1;
break;
elseif (ch==2)
f_desired=f2;
break;
else
fprintf ("wrong channel number please try again \n");
end
end
bpFilt = designfilt('bandpassfir','FilterOrder',35, ...
'CutoffFrequency1',f_desired-Fif,'CutoffFrequency2',f_desired+Fif,...
'SampleRate', fs_new);
message_filtered = filter(bpFilt,final_modulated);
Y4=fft(message_filtered,L_new);
subplot(4,2,4);
plot(k1*fs_new/L_new,abs(fftshift(Y4)));
title('The output of the RF filter (before the mixer)');
%....The mixer stage...%
desired_message= message_filtered.*cos(2*pi*(f_desired+Fif)*n1'*Ts);
Y5=fft(desired_message,L_new);
subplot(4,2,5);
plot(k1*fs_new/L_new,fftshift(abs(Y5)));
title('The output of the mixer');
%....The IF stage....%
bpFilt1 = designfilt('bandpassfir','FilterOrder',50, ...
'CutoffFrequency1',Fif-BW,'CutoffFrequency2',Fif+BW,...
'SampleRate', fs_new);
message_filtered1 = filter(bpFilt1,desired_message);
Y6=fft(message_filtered1,L_new);
subplot(4,2,6);
plot(k1*fs_new/L_new,abs(fftshift(Y6)));
title('The Output of the IF filter');
%....Baseband Detection....%
detected_message = message_filtered1.*cos(2*pi*(Fif)*n1'*Ts);
Y7=fft(detected_message,L_new);
subplot(4,2,7);
plot(k1*fs_new/L_new,abs(fftshift(Y7)));
title('Output of the mixer (before the LPF)');
%...low pass filter to get the Output Message....%
lpFilt = designfilt('lowpassfir', 'filterorder', 200,'CutoffFrequency',9000,'SampleRate', fs_new);
Output_Message = filter(lpFilt,detected_message);
Y8=fft(Output_Message,L_new);
subplot(4,2,8);
plot(k1*fs_new/L_new,abs(fftshift(Y8)));
title('Output of the LPF');
%...listening to the final message....%
Output= downsample(Output_Message,10);
sound(Output,fs1);